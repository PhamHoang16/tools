# 🧰 Phần mềm free hỗ trợ test laptop cũ

`Test-LaptopCu.ps1` đã lo phần lớn: pin, SMART cơ bản, RAM và số kênh, màn gốc, khóa doanh nghiệp,
lỗi ẩn, ép CPU 30 giây. Các tool dưới đây xem **trực quan và sâu hơn**. Tất cả đều **miễn phí, portable**
(không cần cài lên máy người bán).

> ⚡ Cách nhanh: chạy `Download-Tools.ps1` ở nhà (có mạng). Script tự tải và giải nén
> CrystalDiskInfo, CrystalDiskMark, HWiNFO64 vào `PortableTools/`, có kiểm tra file tải về là ZIP thật.

| Tool | Dùng để làm gì | Mức độ |
|------|----------------|--------|
| **CrystalDiskInfo** | SMART ổ cứng/SSD: sức khỏe %, **tổng dữ liệu đã ghi (TBW)**, giờ chạy, số lần bật, nhiệt độ. Đọc được cả khi script báo "Unknown". | ⭐ Rất nên |
| **HWiNFO64** | Mọi cảm biến: **nhiệt độ CPU/GPU**, xung, quạt, công suất sạc, độ chai pin. Chọn *Sensors-only*. | ⭐ Rất nên |
| **CrystalDiskMark** | Đo **tốc độ đọc/ghi**, phát hiện SSD dỏm/chậm bất thường. | Nên |
| **HeavyLoad** (hoặc Prime95) | Ép CPU/GPU lâu hơn (5–10 phút) để soi quá nhiệt. Script đã có bài 30 giây, thường là đủ. | Tuỳ chọn |
| **CPU-Z** | Tab *Memory*: **Channel # Dual/Single**. Tab *SPD*: từng khe RAM. | Tuỳ chọn |

## 🌐 Trang test có sẵn trong thư mục (offline, không cần mạng)
- `screen-test.html`: điểm chết, hở sáng, ố màn.
- `keyboard-test.html`: từng phím, dãy phím số, sơ đồ US/JIS, phát hiện nhảy đúp.
- `media-test.html`: loa trái/phải, quét tần số, mic có ghi âm, webcam.

## 🌐 Trang web dự phòng (cần mạng, ví dụ phát 4G từ điện thoại)
Dùng khi trang offline không chạy, nhất là khi `media-test.html` không được cấp quyền mic/webcam.
- Bàn phím: https://keyboard-test.space (chỉ có sơ đồ US, không bắt nhảy đúp)
- Mic: https://mictests.com
- Webcam: https://webcamtests.com
- Loa trái/phải: https://www.audiocheck.net/audiotests_stereo.php
- Không có mạng: app **Camera** và **Sound Recorder** có sẵn của Windows.

## 🔗 Link tải chính chủ (nếu muốn tải tay)
- CrystalDiskInfo / CrystalDiskMark: https://crystalmark.info/en/software/
- HWiNFO (chọn bản **Portable**): https://www.hwinfo.com/download/
- CPU-Z (bản **zip**): https://www.cpuid.com/softwares/cpu-z.html
- HeavyLoad: https://www.jam-software.com/heavyload

## 📋 Quy trình ngoài tiệm (khoảng 15 phút)
1. Cắm sạc → `Run-Test.bat` → đọc `BaoCao.html` (2 phút).
2. **CrystalDiskInfo** → ổ phải báo **Good** màu xanh. Vàng/đỏ = né.
3. **HWiNFO64** (Sensors-only) để mở → nếu muốn ép lâu thì chạy **HeavyLoad** 5 phút:
   CPU > 95°C liên tục hoặc xung tụt sâu = tản nhiệt kém.
4. `screen-test.html` → `keyboard-test.html` → `media-test.html`.
5. Làm nốt `CHECKLIST.md`: vào BIOS, bản lề, pin phồng, cổng cắm.

> ⚠️ Chỉ tải tool từ **trang chính chủ** ở trên. Tránh bản "full crack".
