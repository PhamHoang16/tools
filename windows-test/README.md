# 💻 Bộ test laptop cũ — Windows 10/11

Bộ công cụ giúp **kiểm tra nhanh laptop cũ trước khi mua**. Mục tiêu: trong ~10 phút,
biết được tình trạng thật của máy (pin, ổ cứng, màn hình, nhiệt độ, bản quyền...) để
quyết định mua hay trả giá. **Không cần biết kỹ thuật** — chủ yếu double-click là chạy.

---

## 🚀 Dùng nhanh (3 bước)

### Ở NHÀ (chuẩn bị, cần mạng)
1. Tải cả thư mục `windows-test` này về USB.
   - Cách dễ: vào https://github.com/PhamHoang16/tools → nút **Code** → **Download ZIP**.
2. (Tuỳ chọn nhưng nên) Click phải `Download-Tools.ps1` → **Run with PowerShell**
   để tải sẵn vài phần mềm portable vào USB (xem `TOOLS.md`).

### Ở TIỆM (test máy, không cần mạng)
3. Cắm USB vào laptop định mua → **double-click `Run-Test.bat`** → bấm **Yes** khi hiện
   cửa sổ xin quyền (UAC) → đợi ~30-60 giây.

   Máy sẽ in kết quả **màu xanh (tốt) / vàng (cảnh báo) / đỏ (kém)** và lưu một thư mục
   báo cáo lên **Desktop** (gồm `BaoCao.txt` + `BatteryReport.html` chi tiết pin).

4. Mở `screen-test.html` (bấm **F11** full màn hình) để soi điểm chết màn hình.
5. Mở `CHECKLIST.md` làm theo để test thủ công (bàn phím, loa, cổng cắm, bản lề...).

---

## 📂 Có gì trong này

| File | Công dụng |
|------|-----------|
| **`Run-Test.bat`** | ⭐ Double-click để chạy. Tự xin quyền admin rồi gọi script. |
| `Test-LaptopCu.ps1` | Script chính (chỉ đọc, không sửa gì máy). Chấm điểm pin, SSD, RAM, CPU, bản quyền... |
| `screen-test.html` | Test điểm chết / hở sáng / độ đều màu màn hình. Mở bằng trình duyệt, offline. |
| `CHECKLIST.md` | Checklist test **thủ công** những thứ script không làm được. In ra/mở điện thoại. |
| `TOOLS.md` | Danh sách phần mềm free nên dùng thêm + link chính chủ. |
| `Download-Tools.ps1` | Chạy ở nhà để tải sẵn tool portable vào USB (chạy offline ngoài tiệm). |

---

## ❓ Nếu Windows chặn không cho chạy

- **SmartScreen** hiện cảnh báo: bấm **More info** → **Run anyway**. (Script là text thuần,
  bạn mở bằng Notepad đọc được toàn bộ — không có gì ẩn.)
- Nếu không chạy được `.bat`, mở **PowerShell** (Start → gõ "powershell") rồi dán:
  ```powershell
  powershell -ExecutionPolicy Bypass -File "<kéo-thả-file-Test-LaptopCu.ps1-vào-đây>"
  ```

## 🔒 An toàn
Tất cả script đều **chỉ đọc thông tin** (read-only): không cài đặt, không xoá, không sửa
hệ thống, không gửi dữ liệu đi đâu. Toàn bộ là mã nguồn mở, bạn đọc được trước khi chạy.

## 🚩 Khi nào nên BỎ máy
Pin < 60%, ổ cứng báo Warning/Unhealthy, màn nhiều điểm chết/hở sáng, máy nóng tự sập,
bản lề lỏng/gãy, serial không khớp. Chi tiết trong `CHECKLIST.md`.
