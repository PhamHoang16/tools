# 💻 Bộ test laptop cũ — Windows 10/11

Bộ công cụ giúp **kiểm tra laptop cũ trước khi mua**. Trong khoảng 15 phút, bạn biết được
tình trạng thật của máy: pin, ổ cứng, RAM chạy một kênh hay hai kênh, màn gốc HD hay FHD,
máy còn bị công ty cũ quản lý không, có lỗi ẩn trong nhật ký không, tản nhiệt có kém không…
Từ đó quyết định **mua, trả giá hay bỏ**. **Không cần biết kỹ thuật**: chủ yếu là double-click.

> 📖 **Hướng dẫn từng bước + cách đọc kết quả: [HUONG-DAN.md](HUONG-DAN.md)**

---

## 🚀 Dùng nhanh

### Ở NHÀ (chuẩn bị, cần mạng)
1. Tải thư mục `windows-test` về USB.
   - Cách dễ: vào https://github.com/PhamHoang16/tools → nút **Code** → **Download ZIP** → giải nén, chép thư mục `windows-test` vào USB.
2. (Nên làm) Click phải `Download-Tools.ps1` → **Run with PowerShell** để tải sẵn
   CrystalDiskInfo, CrystalDiskMark, HWiNFO bản portable vào USB (xem `TOOLS.md`).
3. Mở `CHECKLIST.md` trên điện thoại, đọc phần **0. Hỏi người bán TRƯỚC khi đi**.

### Ở TIỆM (không cần mạng)
4. **Cắm sạc** cho laptop. Cắm USB → **double-click `Run-Test.bat`** → bấm **Yes** ở cửa sổ UAC.
   Chờ 1–2 phút. Có bước ép CPU 30 giây, quạt quay to là bình thường.
5. Báo cáo **`BaoCao.html`** tự mở ra: ở trên cùng là kết luận và danh sách **điểm cần hỏi / để trả giá**.
   Báo cáo được lưu **vào USB** (`windows-test\BaoCao\...`), mang về đọc lại được.
6. Test tay bằng 3 trang offline (mở bằng Edge/Chrome, bấm **F11** toàn màn hình):
   - `screen-test.html`: điểm chết, hở sáng, ố màn.
   - `keyboard-test.html`: từng phím, có cả **dãy phím số** và sơ đồ **bàn phím Nhật (JIS)**; tự phát hiện phím nhảy đúp.
   - `media-test.html`: loa trái/phải, tiếng rè, mic (ghi rồi nghe lại), webcam.
7. Làm nốt `CHECKLIST.md` (bản lề, cổng cắm, pin phồng, vào BIOS…).

---

## 📂 Có gì trong này

| File | Công dụng |
|------|-----------|
| **`HUONG-DAN.md`** | 📖 Hướng dẫn từng bước, cách đọc báo cáo, khi nào bỏ máy. |
| **`Run-Test.bat`** | ⭐ Double-click để chạy. Tự xin quyền admin rồi gọi script. |
| `Test-LaptopCu.ps1` | Script chính, chỉ đọc. Gồm 10 nhóm kiểm tra, xem bảng dưới. |
| `screen-test.html` | Test màn hình: 9 nền màu, dải chuyển, lưới. |
| `keyboard-test.html` | Test bàn phím: US/JIS, phím số, phát hiện nhảy đúp. |
| `media-test.html` | Test loa trái/phải + quét tần số, mic có ghi âm, webcam + độ phân giải. |
| `CHECKLIST.md` | Việc phải làm **bằng tay**, kèm câu hỏi người bán và dấu hiệu nên bỏ. |
| `TOOLS.md` | Phần mềm free dùng thêm + link chính chủ. |
| `Download-Tools.ps1` | Chạy ở nhà để tải sẵn tool portable vào USB (có kiểm tra file tải về là ZIP thật). |
| `dev/Test-Logic.ps1` | Dành cho người sửa script: test các hàm chấm điểm (chạy được cả trên Linux bằng `pwsh`). |

### Script tự động kiểm tra gì

| # | Nhóm | Bắt được |
|---|------|----------|
| 1 | Thông tin máy | Serial trống/mặc định (dấu hiệu **thay mainboard**), link tra **cấu hình gốc** theo serial (Dell hiện cả màn, đèn phím, pin lúc xuất xưởng), TPM, Secure Boot |
| 2 | Pin | % sức khỏe, **pin thay thế khai sai dung lượng** (trên 100%), hãng pin, số lần sạc, BatteryReport |
| 3 | Ổ cứng | Sức khỏe, % hao mòn SSD, giờ chạy, nhiệt độ, lỗi đọc/ghi; bỏ qua USB đang cắm |
| 4 | CPU / RAM | Dung lượng thật, **1 thanh (single-channel) hay 2 thanh (dual-channel)**, thanh lệch, **RAM hàn** (LPDDR) |
| 5 | Màn hình | **Độ phân giải GỐC** của tấm nền (bắt màn HD giả FHD), mã tấm nền để tra IPS/TN |
| 6 | Kết nối | WiFi, Bluetooth, cổng LAN |
| 7 | Bản quyền | Đã kích hoạt chưa, có key gốc trong BIOS không |
| 8 | **Máy doanh nghiệp** | Domain, Azure AD/Entra, MDM (Intune), **Autopilot**, **mật khẩu BIOS** (Dell/HP/Lenovo), **Computrace/Absolute**, BitLocker |
| 9 | Lỗi ẩn | Thiết bị lỗi trong Device Manager, sập nguồn đột ngột, màn hình xanh, lỗi phần cứng WHEA, lỗi ổ đĩa trong nhật ký |
| 10 | Tải CPU 30 giây | Tụt xung mạnh do bụi, keo khô, quạt yếu (bỏ qua bằng `-NoStress`) |

---

## ❓ Nếu Windows chặn không cho chạy

- **SmartScreen** hiện "Windows protected your PC": bấm **More info** → **Run anyway**.
  Script là text thuần, mở bằng Notepad đọc được toàn bộ, không có gì ẩn.
- Nếu `.bat` không chạy, mở **PowerShell** (Start → gõ "powershell") rồi dán:
  ```powershell
  powershell -ExecutionPolicy Bypass -File "<kéo-thả-file-Test-LaptopCu.ps1-vào-đây>"
  ```
- Trang `media-test.html` không hỏi quyền mic/webcam: mở bằng **Edge** hoặc **Chrome**,
  hoặc dùng app **Camera** / **Sound Recorder** có sẵn của Windows.

## 🔒 An toàn
Tất cả **chỉ đọc thông tin**: không cài đặt, không xoá, không sửa hệ thống, không gửi dữ liệu
đi đâu. Bài ép CPU chỉ chạy phép tính 30 giây rồi tự dừng.

## 🚩 Khi nào nên BỎ máy
Pin < 60% hoặc pin phồng, ổ cứng báo Warning/Unhealthy, màn nhiều điểm chết, máy tụt xung
mạnh/tự sập, **mật khẩu BIOS hoặc Autopilot của công ty cũ**, serial không khớp. Chi tiết trong `CHECKLIST.md`.

## 🛠 Cho người sửa script
- Giữ `Test-LaptopCu.ps1` **chỉ ký tự ASCII (không dấu)**. Windows PowerShell 5.1 đọc file
  không BOM theo bảng mã ANSI, có dấu là vỡ chữ.
- Các hàm chấm điểm nằm ở đầu file và không gọi hệ thống. Sau khi sửa, chạy
  `pwsh -NoProfile -File dev/Test-Logic.ps1`.
- `Run-Test.bat` phải giữ xuống dòng CRLF (`.gitattributes` đã khóa).
