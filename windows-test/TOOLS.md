# 🧰 Phần mềm free hỗ trợ test laptop cũ

Script `Test-LaptopCu.ps1` đã lo được phần lớn (pin, SMART cơ bản, RAM, bản quyền...).
Nhưng vài thứ phần mềm chuyên dụng làm **trực quan và sâu hơn**. Đây là các tool
**miễn phí, portable** (không cần cài), nên tải sẵn vào USB ở nhà.

> ⚡ Cách nhanh: chạy `Download-Tools.ps1` ở nhà (có mạng) → nó tự tải các tool
> portable vào thư mục `PortableTools/`. Copy cả USB, ra tiệm cắm chạy offline.

| Tool | Dùng để làm gì | Bắt buộc? |
|------|----------------|-----------|
| **CrystalDiskInfo** | Xem SMART ổ cứng/SSD trực quan: sức khoẻ %, giờ chạy, số lần bật, nhiệt độ. Dễ đọc hơn script. | ⭐ Rất nên |
| **HWiNFO64** | Xem mọi cảm biến: **nhiệt độ CPU/GPU** khi tải nặng, tốc độ quạt, điện áp pin. Phát hiện máy nóng/throttle. | ⭐ Rất nên |
| **CrystalDiskMark** | Đo **tốc độ đọc/ghi** ổ cứng — phát hiện SSD dỏm/chậm bất thường. | Nên |
| **HeavyLoad** (hoặc Prime95) | Ép CPU/GPU 100% vài phút để xem máy có **tự sập / quá nhiệt / quạt kêu** không (stress test). | Tuỳ chọn |

## 🌐 Tool chạy ngay trên trình duyệt (không cần tải)
- **Test bàn phím**: https://keyboard-test.space — bấm thử từng phím, phím nào sáng là nhận.
- **Test điểm chết màn hình**: đã có sẵn file `screen-test.html` (offline, không cần mạng).
- **Test touchpad/chuột**: https://www.onlinemictest.com/trackpad-test/

## 🔗 Link tải chính chủ (nếu muốn tải tay)
- CrystalDiskInfo / CrystalDiskMark: https://crystalmark.info/en/software/
- HWiNFO (chọn bản **Portable**): https://www.hwinfo.com/download/
- HeavyLoad: https://www.jam-software.com/heavyload

## 📋 Quy trình dùng tool ngoài tiệm (gợi ý 10 phút)
1. Chạy `Run-Test.bat` trước → có cái nhìn tổng quan + báo cáo pin.
2. Mở **CrystalDiskInfo** → ổ phải báo **"Good / Tốt"** màu xanh. Đỏ/vàng = né.
3. Mở **HWiNFO** (Sensors only) → để đó.
4. Mở **HeavyLoad** ép CPU ~5 phút → nhìn HWiNFO: CPU nóng tới đâu (>95°C liên tục
   hoặc tụt xung mạnh = tản nhiệt kém), quạt có gào, máy có sập không.
5. Mở `screen-test.html` (F11) soi màn hình.
6. Đối chiếu `CHECKLIST.md` cho phần cơ khí, cổng, loa/mic.

> ⚠️ Lưu ý an toàn: chỉ tải tool từ **trang chính chủ** ở trên. Tránh bản "full crack".
> Các tool này đều sạch và miễn phí cho mục đích cá nhân.
