# linux-oom-freeze-fix

Chống **đơ cứng khi tràn RAM** trên máy Linux desktop RAM thấp (đã kiểm chứng
trên Ubuntu + GNOME, máy 16GB). Triệu chứng: khi cạn RAM máy treo hoàn toàn,
chuột/bàn phím không phản hồi, phải cứng reset — vì kernel OOM-killer phản ứng
quá chậm.

## Cách hoạt động — 3 lớp

| Lớp | Gói | Vai trò |
|---|---|---|
| **earlyoom** | `earlyoom` | Giết **1 process** trước khi kernel kịp làm treo máy. Ưu tiên renderer của trình duyệt (mất 1 tab, reload lại được), tránh process hệ thống (Xorg, gnome-shell, sshd...). Kích hoạt khi RAM trống ≤10% **và** swap trống ≤10%. |
| **zram** | `systemd-zram-generator` | Swap nén trong RAM (zstd, 8G) — nhanh hơn swap file trên disk ~3–4×, chống thrash. |
| **sysctl** | — | `swappiness=180` (ưu tiên đẩy sang zram sớm), `page-cluster=0` (zram random-access), `watermark_scale_factor=125` (phản ứng sớm với sức ép bộ nhớ), `watermark_boost_factor=0` (tắt reclaim chống phân mảnh, tránh giật lag). |

> Mấu chốt là **earlyoom**. zram + sysctl là lớp đệm giảm tần suất phải kill.

> **Không dùng cờ `-g`.** `-g` giết cả process group, mà toàn bộ tiến trình của
> một trình duyệt Chromium thường chung một PGID — nên `-g` làm mất sạch mọi tab
> đang mở chứ không phải "giết 1 tab". Bỏ `-g` thì chỉ 1 renderer bị giết.

## ⚠️ systemd-oomd

Ubuntu 22.04+ **bật sẵn `systemd-oomd`**. Nếu để nguyên, máy bạn có **hai daemon
OOM chạy song song** với chính sách khác nhau: `systemd-oomd` làm việc theo
cgroup + PSI và **không tôn trọng `--prefer`/`--avoid`** của earlyoom, nên nó có
thể bắn trước và chọn sai nạn nhân.

Nên chọn một. Dùng bộ này thì tắt `systemd-oomd`:

```bash
sudo systemctl disable --now systemd-oomd
```

`install.sh` sẽ cảnh báo nếu phát hiện `systemd-oomd` đang chạy, nhưng **không tự
tắt** — đây là quyết định của bạn.

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

Gỡ cài sẽ:

- **Chặn lại nếu nguy hiểm.** Tắt zram nghĩa là nạp ngược toàn bộ dữ liệu trong
  đó về RAM. Nếu lượng đó lớn hơn RAM còn trống, máy sẽ treo ngay trong lúc gỡ —
  đúng cái tình huống bộ này sinh ra để tránh. Script dừng lại và bảo bạn đóng
  bớt ứng dụng hoặc reboot trước. Bỏ qua bằng `sudo ./uninstall.sh --force`.
- **Trả sysctl về mặc định kernel** (`swappiness=60`, `page-cluster=3`,
  `watermark_scale_factor=10`, `watermark_boost_factor=15000`). Chỉ xoá file
  trong `/etc/sysctl.d/` là **chưa đủ** — `sysctl --system` không revert giá trị
  đã nằm trong kernel, và để `swappiness=180` khi zram đã tắt còn tệ hơn trước
  khi cài.
- **Khôi phục config cũ từ bản `.bak-*`** nếu trước đó bạn đã có
  `zram-generator.conf` hoặc `/etc/default/earlyoom` riêng.

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
- **Ngưỡng kích hoạt:** `-m`/`-s` tính theo phần trăm nên khó đoán trên máy RAM
  lớn. Muốn chắc chắn thì dùng dạng tuyệt đối `-M`/`-S` (đơn vị KiB), ví dụ
  `-M 1572864` = bắn khi RAM khả dụng còn dưới 1.5 GiB.
- **Trần RAM cho zram:** `zram-size` là giới hạn **logic**, không phải trần RAM
  thật. Dữ liệu nén tốt (text/DOM/JS) cho tỉ lệ ~4x nên 8 GiB logic chỉ tốn
  ~2 GiB RAM; nhưng gặp dữ liệu đã nén sẵn thì có thể ngốn gần đủ 8 GiB. Muốn
  chặn cứng, đặt `mem_limit`:

  ```bash
  echo 4G | sudo tee /sys/block/zram0/mem_limit     # chỉ có hiệu lực tới khi reboot
  ```

  Để bền qua reboot, thêm vào `/etc/tmpfiles.d/zram-memlimit.conf`:

  ```
  w /sys/block/zram0/mem_limit - - - - 4G
  ```

## Đọc số zram cho đúng

`swapon --show` cột **USED** là dung lượng **logic** đã đẩy vào zram, *không phải*
RAM mà zram chiếm. RAM vật lý thật nằm ở cột **TOTAL** của `zramctl` (hoặc
`mem_used_total`, trường thứ 3 của `/sys/block/zram0/mm_stat`).

Ví dụ thật trên máy 16 GB:

```
swapon --show   USED  6.8G     <- logic, dễ tưởng nhầm là "zram ăn 6.8G RAM"
zramctl         DATA  6.2G  COMPR 1.4G  TOTAL 1.5G
                                             ^^^^ RAM vật lý thực sự chiếm
```

Tỉ lệ nén zstd ~4.4x, tức zram đang **tiết kiệm 4.8 GB RAM**, không phải tiêu tốn.
Thấy con số USED cao là bình thường và là dấu hiệu zram đang làm việc.

## Chỉ dùng cho desktop

Bộ này tune cho máy trạm cá nhân (ưu tiên giữ giao diện phản hồi). **Không** áp
lên server production — ở đó cần chiến lược OOM/cgroup riêng.
