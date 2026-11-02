#!/usr/bin/env bash
#
# install.sh - Tai nghe Bluetooth: nghe A2DP chat luong cao, tu chuyen HFP (co mic)
# khi app mo mic, xong tu ve A2DP. Kem watchdog sua cac kieu ket profile.
#
# Cai cho user hien tai (KHONG can sudo):
#   1. mic ao (loopback PipeWire) -> app luon thay mic, ke ca khi dang A2DP
#   2. them app (Chrome/Electron/Teams...) vao danh sach tu chuyen cua WirePlumber
#   3. watchdog chay moi 30s (systemd --user timer)
#
# Da kiem chung tren Ubuntu 24.04, PipeWire 1.0.5, WirePlumber 0.4.17,
# soundcore Liberty 4 NC.
# Chay: ./install.sh [MAC-tai-nghe]   (bo trong = tu lay tai nghe dang ket noi)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$SCRIPT_DIR/config"
CONF_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
VMIC="bt_headset_mic"

if [[ $EUID -eq 0 ]]; then
  echo "Khong chay bang root: day la cau hinh am thanh cua user. Chay lai: $0" >&2
  exit 1
fi

for cmd in bluetoothctl pw-record; do
  command -v "$cmd" >/dev/null || { echo "Thieu lenh: $cmd" >&2; exit 1; }
done
if ! command -v pactl >/dev/null && [[ ! -x /home/linuxbrew/.linuxbrew/bin/pactl ]]; then
  echo "Thieu pactl. Cai: sudo apt install pulseaudio-utils" >&2
  exit 1
fi
if [[ ! -d /usr/share/wireplumber/policy.lua.d ]]; then
  echo "Canh bao: config/11-bluetooth-autoswitch-apps.lua viet cho WirePlumber 0.4 (cau hinh Lua)." >&2
  echo "WirePlumber 0.5+ dung file .conf -> danh sach app se khong co hieu luc." >&2
fi

MAC="${1:-}"; MAC="${MAC^^}"
if [[ -z "$MAC" ]]; then
  # chi lay thiet bi dang ket noi co Audio Sink (bo chuot/ban phim Bluetooth)
  connected=()
  for m in $(bluetoothctl devices Connected | awk '{print $2}'); do
    bluetoothctl info "$m" | grep -q 'UUID: Audio Sink' && connected+=("$m")
  done
  if [[ ${#connected[@]} -ne 1 ]]; then
    echo "Can dung 1 tai nghe Bluetooth dang ket noi de tu lay MAC (dang co: ${#connected[@]})." >&2
    echo "Chay lai kem MAC: $0 AA:BB:CC:DD:EE:FF   (xem: bluetoothctl devices Paired)" >&2
    exit 1
  fi
  MAC="${connected[0]}"
fi
if [[ ! "$MAC" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
  echo "MAC sai dinh dang: $MAC (vd: AA:BB:CC:DD:EE:FF)" >&2
  exit 1
fi
echo "==> Tai nghe: $MAC ($(bluetoothctl info "$MAC" 2>/dev/null | awk -F': ' '/Name:/ {print $2; exit}'))"

echo "==> [1/4] Watchdog + cau hinh"
install -D -m 0755 "$SCRIPT_DIR/bt-headset-watchdog.sh" "$HOME/.local/bin/bt-headset-watchdog.sh"
mkdir -p "$CONF_HOME"
printf 'MAC="%s"\nVMIC="%s"\n' "$MAC" "$VMIC" > "$CONF_HOME/bt-headset-watchdog.conf"

echo "==> [2/4] Mic ao (PipeWire loopback)"
mkdir -p "$CONF_HOME/pipewire/pipewire.conf.d"
sed -e "s/@MAC_@/${MAC//:/_}/g" -e "s/@VMIC@/$VMIC/g" "$CFG/virtual-mic.conf.in" \
  > "$CONF_HOME/pipewire/pipewire.conf.d/bt-headset-mic.conf"

echo "==> [3/4] Danh sach app tu chuyen (WirePlumber)"
install -D -m 0644 "$CFG/11-bluetooth-autoswitch-apps.lua" \
  "$CONF_HOME/wireplumber/policy.lua.d/11-bluetooth-autoswitch-apps.lua"

echo "==> [4/4] Bat watchdog timer"
install -D -m 0644 "$CFG/bt-headset-watchdog.service" "$CONF_HOME/systemd/user/bt-headset-watchdog.service"
install -D -m 0644 "$CFG/bt-headset-watchdog.timer" "$CONF_HOME/systemd/user/bt-headset-watchdog.timer"
systemctl --user daemon-reload
systemctl --user enable --now bt-headset-watchdog.timer

echo
echo "==> Xong. Mic ao + danh sach app co hieu luc tu lan DANG NHAP LAI tiep theo."
echo "  Khong nen restart pipewire/wireplumber giua phien: tai nghe de ket A2DP 'busy',"
echo "  va Chrome/Electron mat ket noi am thanh toi khi khoi dong lai app."
echo "Kiem tra sau khi dang nhap lai:"
echo "  pactl get-default-source          # = $VMIC"
echo "  journalctl --user -u bt-headset-watchdog.service --since -1h | grep -v -e Starting -e Finished"
echo
echo "Go cai: ./uninstall.sh"
