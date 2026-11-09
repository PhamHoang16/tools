# 📖 Hướng dẫn sử dụng: test laptop cũ trước khi mua

Ba bước: **chuẩn bị USB ở nhà → chạy test tự động ở tiệm → test bằng tay ở tiệm**.
Tổng cộng khoảng 15–20 phút.

---

## 1. Ở nhà: chuẩn bị USB (5 phút, cần mạng, làm trên máy Windows)

1. Vào https://github.com/PhamHoang16/tools → nút **Code** → **Download ZIP**.
   Giải nén, chép **cả thư mục `windows-test`** vào USB.
2. Mở thư mục `windows-test` trên USB → click phải **`Download-Tools.ps1`** → **Run with PowerShell**.
   Script tự tải CrystalDiskInfo, CrystalDiskMark, HWiNFO64 (bản portable) vào thư mục `PortableTools`.
   - Tool nào báo **LỖI** thì tải tay theo link in ra màn hình.
3. Nhắn người bán theo mục **"0. Hỏi người bán TRƯỚC khi đi"** trong `CHECKLIST.md`:
   ảnh tem đáy máy (serial), ảnh RAM (CPU-Z tab Memory), ảnh độ phân giải màn hình, layout bàn phím, bảo hành.

## 2. Ở tiệm: chạy test tự động (2 phút)

1. **Cắm sạc** cho laptop. Nếu chạy bằng pin, bài test CPU sẽ cho kết quả thấp hơn thực tế.
2. Cắm USB → double-click **`Run-Test.bat`** → bấm **Yes** khi Windows hỏi quyền (UAC).
   - Nếu hiện *"Windows protected your PC"*: bấm **More info** → **Run anyway**.
3. Chờ 1–2 phút. Có bước **ép CPU 30 giây**: quạt quay to là bình thường, đừng tắt máy.
4. File **`BaoCao.html`** tự mở ra:
   - **Dòng trên cùng** là kết luận: 🟢 ổn · 🟡 có điểm cần lưu ý · 🔴 nên bỏ hoặc trả giá mạnh.
   - Phần **"Cần hỏi người bán / dùng để trả giá"** gom sẵn mọi mục vàng và đỏ, **đọc phần này trước**.
   - Báo cáo được lưu luôn vào USB (`windows-test\BaoCao\<model>_<serial>_<giờ>\`) để mang về xem lại.
     Nếu USB không ghi được thì báo cáo nằm trên Desktop của máy.

> Muốn bỏ bài ép CPU (ví dụ máy đang chạy pin): mở PowerShell trong thư mục USB rồi chạy
> `powershell -ExecutionPolicy Bypass -File .\Test-LaptopCu.ps1 -NoStress`

## 3. Ở tiệm: test bằng tay (10 phút)

Mở từng file bằng **Edge** hoặc **Chrome**, bấm **F11** để xem toàn màn hình:

| File | Làm gì | Dấu hiệu xấu |
|------|--------|--------------|
| `screen-test.html` | Click chuột (hoặc phím →) để đổi màu nền | Chấm đen/chấm sáng không đổi màu; loang sáng ở mép trên nền đen; vết ố trên nền trắng |
| `keyboard-test.html` | Bấm từng phím đến khi **xanh hết**, cả dãy phím số. Máy bàn phím Nhật thì chọn **JIS** | Phím không lên xanh; phím chuyển **đỏ** (nhảy đúp) |
| `media-test.html` | Loa **Trái/Phải** → **Quét tần số** → **Bật mic** → **Ghi 5 giây** nghe lại → **Bật webcam** | Phát trái mà nghe bên phải; rè/lạch xạch; mic không nhảy; webcam đen/sọc |

Nếu `media-test.html` không hỏi quyền mic/webcam: dùng app **Camera** và **Sound Recorder** có sẵn
của Windows, hoặc trang web dự phòng trong `TOOLS.md` (cần mạng).

Cuối cùng làm nốt **`CHECKLIST.md`** trên điện thoại. Quan trọng nhất:
- **Khởi động lại, vào BIOS** (Dell: F2, Lenovo: F1/Enter, HP: F10): phải vào được **không bị hỏi mật khẩu**;
  serial trong BIOS **trùng** tem dưới đáy máy.
- **Pin phồng**: đặt máy trên bàn phẳng xem đáy có vênh không, touchpad có bị cộm lên không.
- **Bản lề** và **từng cổng cắm** (USB, USB-C, HDMI, jack tai nghe, cổng sạc).
- **Settings → Accounts → Access work or school** phải trống.

---

## Đọc kết quả và quyết định

**🔴 Nên BỎ** (trừ khi người bán xử lý ngay trước mặt bạn):
- Mật khẩu BIOS, Windows Autopilot, MDM của công ty cũ.
- Pin phồng, hoặc sức khỏe pin dưới 60%.
- Ổ cứng báo Warning/Unhealthy, có lỗi không sửa được.
- Serial trống hoặc không khớp giữa Windows, BIOS và tem dưới đáy.
- Máy tụt xung mạnh, nóng tự sập; rao FHD mà màn gốc là HD.

**🟡 Dùng để TRẢ GIÁ:**
- RAM 1 thanh (single-channel): phải mua thêm 1 thanh.
- Pin còn 60–80%, SSD đã hao mòn, nhiều giờ chạy.
- Thiếu đèn phím, thiếu driver, Windows chưa kích hoạt.

**🟢 Không có mục đỏ, mục vàng chấp nhận được** → có thể mua. Nhớ đòi **bảo hành ít nhất 3 tháng và đổi trả 7 ngày**.
