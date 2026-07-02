# linux-oom-freeze-fix

Chống **đơ cứng khi tràn RAM** trên máy Linux desktop RAM thấp (đã kiểm chứng
trên Ubuntu + GNOME, máy 16GB). Triệu chứng: khi cạn RAM máy treo hoàn toàn,
chuột/bàn phím không phản hồi, phải cứng reset — vì kernel OOM-killer phản ứng
quá chậm.

## Cách hoạt động — 3 lớp

| Lớp | Gói | Vai trò |
|---|---|---|
| **earlyoom** | `earlyoom` | Giết 1 process **trước khi** kernel kịp làm treo máy. Ưu tiên tab trình duyệt, tránh process hệ thống (Xorg, gnome-shell, sshd...). Kích hoạt khi RAM trống ≤5% **và** swap trống ≤5%. |
| **zram** | `systemd-zram-generator` | Swap nén trong RAM (zstd, 8G) — nhanh hơn swap file trên disk ~3–4×, chống thrash. |
| **sysctl** | — | `swappiness=180` (ưu tiên đẩy sang zram sớm), `page-cluster=0` (zram random-access), `watermark_scale_factor=125` (phản ứng sớm với sức ép bộ nhớ). |

> Mấu chốt là **earlyoom**. zram + sysctl là lớp đệm giảm tần suất phải kill.

## Cài

```bash
git clone git@github.com:PhamHoang16/tools.git
cd tools/linux-oom-freeze-fix
sudo ./install.sh
```

Script tự cài gói, sao lưu config cũ (`*.bak-<timestamp>`), đặt config trong
`config/` vào chỗ, bật dịch vụ. Idempotent — chạy lại nhiều lần vô hại.

## Kiểm tra

```bash
systemctl status earlyoom --no-pager
zramctl ; swapon --show
sysctl vm.swappiness vm.page-cluster vm.watermark_scale_factor
journalctl -u earlyoom -f     # xem log giám sát RAM/swap theo thời gian thực
```

## Gỡ

```bash
sudo ./uninstall.sh                                          # tắt dịch vụ + gỡ config
sudo apt-get remove earlyoom systemd-zram-generator          # (tùy chọn) gỡ hẳn gói
```

## File cấu hình

| File trong repo | Đích trên máy |
|---|---|
| `config/earlyoom.default` | `/etc/default/earlyoom` |
| `config/zram-generator.conf` | `/etc/systemd/zram-generator.conf` |
| `config/99-freeze-fix.conf` | `/etc/sysctl.d/99-freeze-fix.conf` |

## Tinh chỉnh

- **Máy RAM khác 16G:** zram tự dùng `min(ram, 8192)` MiB — chỉnh trong
  `zram-generator.conf` nếu muốn khác.
- **Ứng dụng ưu tiên bị giết:** sửa regex `--prefer` trong `earlyoom.default`
  (mặc định: các trình duyệt Chromium/Firefox/Edge).
- **Không dùng trình duyệt là thủ phạm chính:** bỏ `--prefer`, earlyoom sẽ chọn
  process tốn RAM nhất.

## Chỉ dùng cho desktop

Bộ này tune cho máy trạm cá nhân (ưu tiên giữ giao diện phản hồi). **Không** áp
lên server production — ở đó cần chiến lược OOM/cgroup riêng.
