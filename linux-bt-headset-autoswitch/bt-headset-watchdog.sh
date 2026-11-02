#!/usr/bin/env bash
# Watchdog tai nghe Bluetooth (chạy mỗi 30s qua systemd --user timer). Viết cho soundcore Liberty 4 NC,
# dùng được cho tai nghe Bluetooth Classic bất kỳ (A2DP + HFP).
#  - HFP + không app nào thu mic qua 2 lần kiểm liên tiếp -> chuyển về A2DP tốt nhất (LDAC > SBC-XQ > SBC)
#  - kẹt audio-gateway/off, hoặc A2DP rớt -> xin lại A2DP; không được thì kết nối lại, tối đa 1 lần / 10 phút
#  - WirePlumber nhớ nhầm profile có mic, hoặc HFP không có mic -> tự sửa (xem chú thích bên dưới)
#  - giữ mic mặc định là mic ảo (xem config/virtual-mic.conf.in)
# Cấu hình: ~/.config/bt-headset-watchdog.conf (MAC=..., VMIC=...), do install.sh tạo.
set -u
# pactl có thể chỉ có qua linuxbrew (không có pulseaudio-utils); systemd --user không có đường dẫn đó trong PATH
export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
command -v pactl >/dev/null || { echo "LỖI: không tìm thấy pactl (sudo apt install pulseaudio-utils)"; exit 1; }
MAC=""; VMIC="bt_headset_mic"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/bt-headset-watchdog.conf"
[ -f "$CONF" ] && . "$CONF"
[ -z "$MAC" ] && { echo "LỖI: chưa đặt MAC tai nghe trong $CONF"; exit 1; }
CARD="bluez_card.${MAC//:/_}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/bt-headset-watchdog"
mkdir -p "$STATE_DIR"
log() { echo "$*"; }
# Profile A2DP tốt nhất đang có: LDAC (a2dp-sink khi codec LDAC) > SBC-XQ > a2dp-sink.
# Bật kết nối kép trong app Soundcore thì LDAC biến mất, chỉ còn SBC/SBC-XQ.
best_a2dp() {
  local c; c=$(pactl list cards | awk -v c="Name: $CARD" '$0 ~ c {p=1} p' | grep -E '^\s+a2dp-sink[^ ]*:.*available: yes')
  if echo "$c" | grep -qE '^\s+a2dp-sink:.*LDAC'; then echo a2dp-sink
  elif echo "$c" | grep -qE '^\s+a2dp-sink-sbc_xq:'; then echo a2dp-sink-sbc_xq
  else echo a2dp-sink; fi
}
notify() { notify-send -a "Bluetooth watchdog" "Tai nghe" "$1" 2>/dev/null || true; }

card_info=$(pactl list cards 2>/dev/null | awk -v c="Name: $CARD" '$0 ~ c {p=1} p && /^Card #/ && seen {exit} p {seen=1; print}')
[ -z "$card_info" ] && { rm -f "$STATE_DIR/idle_hfp"; exit 0; }   # tai nghe không kết nối

profile=$(echo "$card_info" | awk '/Active Profile/ {print $3; exit}')
a2dp_avail=$(echo "$card_info" | grep -cE '^\s+a2dp-sink:.*available: yes')

# Luồng thu của app thật (bỏ loopback của mic ảo và đồng hồ đo của GNOME Settings)
app_streams=$(pactl list source-outputs 2>/dev/null | grep -E 'application.name = ' \
  | grep -vE '"(GNOME Settings|PipeWire|pipewire)"' | wc -l)

# Giữ mic ảo làm mặc định
if pactl list short sources | grep -q $'\t'"$VMIC"$'\t' && [ "$(pactl get-default-source)" != "$VMIC" ]; then
  pactl set-default-source "$VMIC" && log "đặt lại mic mặc định = $VMIC"
fi

# WirePlumber nhớ "profile có mic" của tai nghe (saved-headset-profile) để tự chuyển khi app mở mic.
# Nếu nó bị ghi nhầm thành a2dp-* (lỗi 2026-11-02: tai nghe rớt giữa lúc đang gọi / watchdog chuyển
# profile chen ngang), app mở mic sẽ "chuyển" sang chính A2DP -> mic im lặng mãi, và lỗi tự duy trì.
# Sửa trong bộ nhớ WirePlumber không cần restart: mở 1 luồng Communication (WP ghi nhớ profile hiện tại),
# đặt profile HFP, đóng luồng -> sau 2s WP lưu HFP làm profile có mic và tự trả về A2DP.
wp_state="${XDG_STATE_HOME:-$HOME/.local/state}/wireplumber/policy-bluetooth"
saved_hs=$(sed -n "s/^saved-headset-profile:$CARD=//p" "$wp_state" 2>/dev/null)
if [[ "$profile" == a2dp-sink* && -n "$saved_hs" && "$saved_hs" != headset-head-unit* && "$app_streams" -eq 0 ]]; then
  hs=$(echo "$card_info" | grep -oE '^\s+headset-head-unit-msbc:.*available: yes' >/dev/null && echo headset-head-unit-msbc || echo headset-head-unit)
  timeout 8 pw-record --target "$VMIC" -P '{ media.role = "Communication", application.name = "bt-headset-watchdog" }' \
    "$STATE_DIR/fix.wav" >/dev/null 2>&1 &
  rec=$!
  sleep 1.5
  pactl set-card-profile "$CARD" "$hs"
  sleep 1.5
  kill "$rec" 2>/dev/null; wait "$rec" 2>/dev/null; rm -f "$STATE_DIR/fix.wav"
  sleep 4
  log "sửa profile mic WirePlumber nhớ nhầm: $saved_hs -> $(sed -n "s/^saved-headset-profile:$CARD=//p" "$wp_state"), profile giờ: $(pactl list cards | awk -v c="Name: $CARD" '$0 ~ c {p=1} p && /Active Profile/ {print $3; exit}')"
  exit 0
fi

case "$profile" in
  headset-head-unit*|audio-gateway|off)
    # audio-gateway: WirePlumber coi tai nghe là nguồn phát (tai nghe khai báo cả Audio Source sau khi
    # ghép lại 2026-10-28) -> máy không có loa tai nghe. Sửa ngay, không cần chờ.
    if [[ "$profile" == headset-head-unit* ]]; then
      # Lỗi 2026-11-02: sau khi tai nghe rớt sóng, profile HFP chọn được nhưng PipeWire không tạo
      # bluez_input (kênh HFP chết) -> app mở mic nhưng im lặng. Chỉ kết nối lại tai nghe mới gỡ được.
      if ! pactl list short sources | grep -q "bluez_input.${MAC//:/_}"; then
        if [ ! -f "$STATE_DIR/hfp_no_mic" ]; then touch "$STATE_DIR/hfp_no_mic"; exit 0; fi  # chờ thêm 1 chu kỳ
        rm -f "$STATE_DIR/hfp_no_mic"
        last=$(cat "$STATE_DIR/last_reconnect" 2>/dev/null || echo 0); now=$(date +%s)
        if [ $((now - last)) -ge 600 ]; then
          echo "$now" > "$STATE_DIR/last_reconnect"
          log "HFP không có mic (kênh HFP chết) -> kết nối lại tai nghe"
          timeout 15 bluetoothctl disconnect "$MAC" >/dev/null 2>&1; sleep 4
          timeout 25 bluetoothctl connect "$MAC" >/dev/null 2>&1
        fi
        exit 0
      fi
      rm -f "$STATE_DIR/hfp_no_mic"
      if [ "$app_streams" -gt 0 ]; then rm -f "$STATE_DIR/idle_hfp"; exit 0; fi   # đang họp
      if [ ! -f "$STATE_DIR/idle_hfp" ]; then touch "$STATE_DIR/idle_hfp"; exit 0; fi  # chờ thêm 1 chu kỳ
    fi
    rm -f "$STATE_DIR/idle_hfp"
    if [ "$a2dp_avail" -gt 0 ]; then
      pactl set-card-profile "$CARD" "$(best_a2dp)" && log "HFP rảnh -> chuyển về $(best_a2dp)"
    else
      # Kết nối kép: điện thoại có thể giữ A2DP của tai nghe ("Stream End Point in Use").
      # Mỗi chu kỳ xin lại riêng A2DP (nhẹ, không ngắt tai nghe) để lấy lại ngay khi điện thoại nhả.
      # Kênh A2DP ngược (tai nghe -> máy, UUID 110a) chiếm chỗ làm A2DP xuôi báo "busy": ngắt nó trước.
      timeout 10 busctl call org.bluez "/org/bluez/hci0/dev_${MAC//:/_}" org.bluez.Device1 \
           DisconnectProfile s 0000110a-0000-1000-8000-00805f9b34fb >/dev/null 2>&1 && sleep 2
      if timeout 15 busctl call org.bluez "/org/bluez/hci0/dev_${MAC//:/_}" org.bluez.Device1 \
           ConnectProfile s 0000110b-0000-1000-8000-00805f9b34fb >/dev/null 2>&1; then
        sleep 3
        if pactl list cards | grep -qE '^\s+a2dp-sink:.*available: yes'; then
          pactl set-card-profile "$CARD" "$(best_a2dp)" && log "xin lại A2DP thành công -> $(best_a2dp)"
          exit 0
        fi
      fi
      last=$(cat "$STATE_DIR/last_reconnect" 2>/dev/null || echo 0); now=$(date +%s)
      if [ $((now - last)) -ge 600 ]; then
        echo "$now" > "$STATE_DIR/last_reconnect"
        log "A2DP mất -> kết nối lại tai nghe"
        timeout 15 bluetoothctl disconnect "$MAC" >/dev/null 2>&1; sleep 4
        timeout 25 bluetoothctl connect "$MAC" >/dev/null 2>&1; sleep 6
        if pactl list cards | grep -qE '^\s+a2dp-sink:.*available: yes'; then
          pactl set-card-profile "$CARD" "$(best_a2dp)" && log "đã khôi phục $(best_a2dp)"
        else
          log "KHÔNG khôi phục được A2DP (busy) -> điện thoại đang giữ A2DP, hoặc cần reset tai nghe/adapter"
          lastn=$(cat "$STATE_DIR/last_notify" 2>/dev/null || echo 0)
          if [ $((now - lastn)) -ge 1800 ]; then
            echo "$now" > "$STATE_DIR/last_notify"
            notify "Tai nghe mất kênh nghe chất lượng cao. Ngắt tai nghe khỏi điện thoại, hoặc cho tai nghe vào hộp 10s."
          fi
        fi
      fi
    fi
    ;;
  *) rm -f "$STATE_DIR/idle_hfp" ;;
esac
