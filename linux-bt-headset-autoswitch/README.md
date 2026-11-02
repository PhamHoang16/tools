# linux-bt-headset-autoswitch

Tai nghe Bluetooth trên Linux: **nghe nhạc chất lượng cao (A2DP) bình thường,
tự chuyển sang chế độ gọi (HFP, có mic) khi app mở mic, xong tự về A2DP** —
kèm watchdog tự gỡ các kiểu kẹt profile hay gặp. Đã kiểm chứng trên Ubuntu
24.04 (PipeWire 1.0.5, WirePlumber 0.4.17) với soundcore Liberty 4 NC qua
adapter USB Bluetooth.

## Vì sao cần

Tai nghe Bluetooth Classic không thể vừa nghe chất lượng cao vừa dùng mic:
A2DP (LDAC/SBC-XQ) chỉ có chiều phát, HFP có mic nhưng âm thanh mono 16 kHz.
WirePlumber có sẵn cơ chế tự chuyển, nhưng thực tế hỏng theo nhiều cách:

| Triệu chứng | Nguyên nhân |
|---|---|
| App (Chrome, Electron, Telegram web…) báo **"no device found"** khi bật mic | Ở A2DP tai nghe không có mic nào → app không mở luồng thu → WirePlumber không bao giờ chuyển sang HFP |
| App mở mic nhưng **không tự chuyển** | App không đặt `media.role=Communication` và không có trong danh sách app của WirePlumber |
| **Kẹt ở HFP** (tiếng tệ) dù đã tắt mic | Luồng thu bị "cork" chứ không đóng, WirePlumber không trả về A2DP |
| Mất loa tai nghe, tiếng ra loa máy, profile **`audio-gateway`/`off`** | Sau khi ghép lại, tai nghe khai báo thêm Audio Source; WirePlumber chọn nhầm vai |
| A2DP **"busy"** sau khi tai nghe kết nối | Bật kết nối kép (multipoint), điện thoại đang giữ A2DP |
| Mở mic nhưng **thu ra im lặng tuyệt đối** | Tai nghe rớt sóng lúc đang HFP → WirePlumber nhớ nhầm "profile có mic" là A2DP (lỗi tự duy trì), hoặc kênh HFP chết không còn node mic |

## Cách hoạt động — 3 lớp

| Lớp | File | Vai trò |
|---|---|---|
| **Mic ảo** | `config/virtual-mic.conf.in` | Loopback PipeWire `bt_headset_mic` luôn tồn tại, nối vào mic thật của tai nghe. App luôn thấy mic → mở mic ảo → WirePlumber chuyển HFP → mic thật xuất hiện → loopback tự nối. |
| **Danh sách app** | `config/11-bluetooth-autoswitch-apps.lua` | Thêm Chrome/Electron/Claude/Slack/Teams/Discord… vào danh sách app được tự chuyển. |
| **Watchdog** | `bt-headset-watchdog.sh` + systemd `--user` timer 30s | Gỡ mọi kiểu kẹt ở bảng trên; giữ mic ảo làm mic mặc định. |

Watchdog làm gì, theo profile hiện tại:

- **HFP mà không app nào dùng mic** 2 lần kiểm liên tiếp → về A2DP tốt nhất
  đang có (LDAC > SBC-XQ > SBC).
- **HFP mà không có node mic** (kênh HFP chết) 2 lần liên tiếp → kết nối lại tai nghe.
- **`audio-gateway`/`off`, hoặc A2DP biến mất** → ngắt kênh A2DP ngược (UUID
  110a), xin lại A2DP (110b) qua D-Bus mỗi chu kỳ; không được thì kết nối lại
  tai nghe (tối đa 1 lần / 10 phút); vẫn không được thì báo notify (tối đa 1
  lần / 30 phút).
- **WirePlumber nhớ nhầm profile có mic** (`saved-headset-profile` trong
  `~/.local/state/wireplumber/policy-bluetooth` là `a2dp-*`) → mở một luồng
  Communication, đặt HFP, đóng luồng → WirePlumber tự lưu lại HFP và trả về
  A2DP. Không cần restart WirePlumber.

## Cài

```bash
git clone git@github.com:PhamHoang16/tools.git
cd tools/linux-bt-headset-autoswitch
./install.sh                      # tự lấy tai nghe đang kết nối
./install.sh AA:BB:CC:DD:EE:FF    # hoặc chỉ định MAC (bluetoothctl devices Paired)
```

Cài cho user hiện tại, **không cần sudo**. Cần `pactl` (`sudo apt install
pulseaudio-utils`), `bluetoothctl`, `pw-record`. Watchdog chạy ngay; mic ảo và
danh sách app có hiệu lực từ **lần đăng nhập lại** tiếp theo.

> **Đừng restart pipewire/wireplumber giữa phiên** để "áp dụng ngay": tai nghe
> dễ kẹt A2DP "busy" (chỉ gỡ được bằng cho tai nghe vào hộp / cắm lại adapter),
> và Chrome/Electron giữ kết nối âm thanh chết (`pa_operation is nullptr`) tới
> khi khởi động lại app.

## Kiểm tra

```bash
pactl get-default-source          # = bt_headset_mic
pactl list cards | grep 'Active Profile'
systemctl --user status bt-headset-watchdog.timer --no-pager
# watchdog đã can thiệp những gì:
journalctl --user -u bt-headset-watchdog.service --since -2h | grep -v -e Starting -e Finished

# thử mic: phải thấy profile sang headset-head-unit* rồi tự về a2dp-sink*, peak > 0
pw-record --target bt_headset_mic -P '{ media.role = "Communication" }' --rate 16000 --channels 1 /tmp/mic.wav
```

## Gỡ

```bash
./uninstall.sh                    # tắt watchdog + gỡ file; đăng nhập lại để bỏ mic ảo
```

## File cấu hình

| File trong repo | Đích trên máy |
|---|---|
| `bt-headset-watchdog.sh` | `~/.local/bin/bt-headset-watchdog.sh` |
| (install.sh tạo: `MAC`, `VMIC`) | `~/.config/bt-headset-watchdog.conf` |
| `config/virtual-mic.conf.in` | `~/.config/pipewire/pipewire.conf.d/bt-headset-mic.conf` |
| `config/11-bluetooth-autoswitch-apps.lua` | `~/.config/wireplumber/policy.lua.d/11-bluetooth-autoswitch-apps.lua` |
| `config/bt-headset-watchdog.{service,timer}` | `~/.config/systemd/user/` |

## Giới hạn

- **Lúc đang dùng mic, tiếng vẫn là chất lượng cuộc gọi** (mono 16 kHz, mSBC)
  — giới hạn của Bluetooth Classic, không phần mềm nào vượt được. Muốn cả hai
  cùng lúc cần tai nghe LE Audio hoặc mic rời.
- **Kết nối kép (multipoint)** trên nhiều tai nghe tắt LDAC (còn SBC-XQ) và để
  điện thoại tranh A2DP. Watchdog tự giành lại, nhưng tắt kết nối kép khi ngồi
  máy sẽ ổn định hơn.
- Danh sách app viết cho **WirePlumber 0.4** (cấu hình Lua). WirePlumber 0.5+
  dùng `.conf` → file Lua không có hiệu lực (mic ảo và watchdog vẫn chạy).
- Thêm app không tự chuyển: xem `application.name` bằng `pactl list
  source-outputs` lúc app đang mở mic, thêm vào `config/11-bluetooth-autoswitch-apps.lua`.
