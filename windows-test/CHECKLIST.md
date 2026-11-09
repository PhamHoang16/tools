# ✅ Checklist test laptop cũ

> `Run-Test.bat` lo phần tự động (pin, ổ cứng, RAM, màn gốc, khóa doanh nghiệp, lỗi ẩn, tản nhiệt).
> File này là những thứ **máy không tự kiểm tra được**: bạn phải tự hỏi, soi, bấm, nghe.
> Mở trên điện thoại, tick từng mục khi đi xem máy.

---

## 0. Hỏi người bán TRƯỚC khi đi (nhắn tin)
- [ ] Ảnh **tem dưới đáy máy** có Service Tag / Serial. Tra trên web hãng (Dell hiện cả cấu hình gốc).
- [ ] Ảnh **CPU-Z tab Memory** (hoặc Task Manager → Memory): RAM mấy thanh, có chạy **Dual** không.
- [ ] Ảnh **Settings → Display**: độ phân giải ghi *(Recommended)* phải là **1920×1080** nếu rao FHD.
- [ ] Bàn phím layout gì (US / Nhật / Anh…), **có đèn phím không**, có dãy phím số không.
- [ ] Pin zin hay pin thay. Sạc zin hay sạc lô, bao nhiêu W.
- [ ] Bảo hành bao lâu, **đổi trả mấy ngày**. Nên có ít nhất 3 tháng bảo hành và 7 ngày đổi trả.

## 1. Mang theo
- [ ] USB chứa thư mục `windows-test` (đã chạy `Download-Tools.ps1` ở nhà).
- [ ] Tai nghe 3.5 mm, chuột USB, điện thoại (đèn flash + phát WiFi 4G).
- [ ] Một thiết bị USB-C (sạc điện thoại, ổ USB-C) để thử cổng USB-C/Thunderbolt.

## 2. Ngoại hình, khung máy, dấu hiệu "máy dựng"
- [ ] Vỏ: móp, nứt, trầy nặng? **Ốc vít bị toét** = đã mở máy nhiều.
- [ ] **Bản lề**: gập mở êm, không kêu rắc, không lỏng. Màn đứng yên ở mọi góc.
- [ ] **Pin phồng**: đặt máy trên bàn phẳng xem đáy có **vênh, cập kênh** không; touchpad **cộm, khó bấm, bị đẩy lên**; khe vỏ hở. Pin phồng = phải thay ngay, nguy cơ cháy.
- [ ] Máy dựng / thay vỏ: vỏ **mới tinh** mà phím **bóng mòn**, màu vỏ các mặt lệch nhau, khe ghép không đều.
- [ ] Tem serial dưới đáy **trùng** với serial script in ra và với serial trong BIOS.
- [ ] Khe tản nhiệt: bụi dày, mùi khét.

## 3. Vào BIOS (quan trọng với máy doanh nghiệp: Latitude, ThinkPad, EliteBook)
Khởi động lại, bấm liên tục **F2** (Dell) / **F1** hoặc **Enter** (Lenovo) / **F10** (HP) / **Del** (Asus, MSI…).
- [ ] Vào được **mà không bị hỏi mật khẩu**.
- [ ] Service Tag / Serial trong BIOS **trùng tem dưới đáy**. Không trùng = đã thay mainboard.
- [ ] Mục **Absolute / Computrace** (thường ở Security): nên là *Disabled/Deactivated*. *Activated* = máy còn bị theo dõi.
- [ ] Battery Information (Dell): tình trạng pin, sạc có được nhận đúng công suất không.

## 4. Màn hình (`screen-test.html`, bấm F11)
- [ ] **Điểm chết / điểm kẹt màu**: soi kỹ nền đỏ, lục, lam, trắng, đen.
- [ ] **Hở sáng**: nền đen, soi 4 mép và góc có loang sáng không.
- [ ] **Ố, đốm, ngả vàng** trên nền trắng; vết xước, bong lớp chống chói.
- [ ] Kéo độ sáng max: đủ sáng không, chỉnh độ sáng có ăn không.
- [ ] Nhìn nghiêng 45°: màu đảo, tối hẳn = tấm nền TN rẻ tiền (script có in mã tấm nền để tra).
- [ ] Cảm ứng (nếu có): vuốt khắp màn.

## 5. Bàn phím, touchpad (`keyboard-test.html`)
- [ ] Bấm **đủ từng phím** đến khi xanh hết, cả **dãy phím số** (thử cả NumLock bật/tắt).
- [ ] Không phím nào **đỏ** (nhảy đúp), không phím nào phải bấm mạnh mới ăn.
- [ ] Phím **Fn** + phím chức năng: độ sáng, âm lượng, tắt mic, bật/tắt WiFi, **đèn phím** (sáng đều không).
- [ ] Bàn phím **Nhật (JIS)**: chọn sơ đồ JIS; thử gõ email có `@`, công thức Excel, xem có quen tay được không.
- [ ] Touchpad: di khắp mặt, click trái/phải, cuộn 2 ngón, không nhảy chuột.
- [ ] Đầu đọc vân tay / camera IR (nếu có): Settings → Accounts → Sign-in options thử thêm vân tay.

## 6. Loa, mic, webcam (`media-test.html`)
- [ ] Loa **trái** phát bên trái, **phải** phát bên phải, không câm bên nào.
- [ ] **Quét tần số**: không rè, không lạch xạch ở đoạn trầm.
- [ ] Cắm tai nghe: có tiếng, lay jack không sột soạt.
- [ ] Mic: thanh mức nhảy khi nói; ghi 5 giây nghe lại rõ, không ù.
- [ ] Webcam: hình rõ, không sọc; xem độ phân giải (720p hay 1080p).

## 7. Cổng kết nối (thử TỪNG cổng)
- [ ] Mọi cổng **USB-A**: cắm chuột/USB, đảo qua từng cổng.
- [ ] **USB-C / Thunderbolt**: cắm thử thiết bị; nếu máy sạc qua USB-C thì thử sạc qua đó.
- [ ] **HDMI**: xuất ra màn ngoài/TV nếu tiệm có.
- [ ] Cổng **LAN**, khe **thẻ nhớ** (nếu có).
- [ ] **Cổng sạc**: icon báo đang sạc, lay dây không chập chờn. Sạc ghi đúng **số W** máy cần
      (Dell báo "AC adapter not identified" / "chậm sạc" khi sạc không đúng).

## 8. Kết nối không dây
- [ ] **WiFi**: vào mạng 4G từ điện thoại, mở web, không rớt.
- [ ] **Bluetooth**: dò thấy điện thoại / tai nghe.

## 9. Windows và tài khoản
- [ ] **Settings → Accounts → Access work or school**: phải **trống**.
- [ ] Không có dòng *"Some settings are managed by your organization"* trong Settings.
- [ ] Windows đã kích hoạt (script có kiểm tra). Máy Nhật/Mỹ: đã cài lại Windows tiếng Anh/Việt chưa.

## 10. Nhiệt độ và pin thực tế (nếu có thời gian)
- [ ] Script đã ép CPU 30 giây. Muốn kỹ hơn: mở **HWiNFO64** (Sensors) + **HeavyLoad** 5 phút. CPU > 95°C liên tục hoặc máy sập = tản nhiệt kém.
- [ ] Quạt: có quay, không có tiếng rít (bạc đạn khô).
- [ ] Rút sạc, dùng ~10 phút xem % pin tụt có bất thường không.

---

## 🚩 Dấu hiệu NÊN BỎ / TRẢ GIÁ MẠNH
- Pin sức khỏe < 60%, **pin phồng**, hoặc không nhận pin.
- Ổ cứng báo **Warning/Unhealthy**, SSD còn < 50% tuổi thọ, có lỗi không sửa được.
- **Mật khẩu BIOS**, **Autopilot**, MDM của công ty cũ mà người bán không gỡ được → **BỎ**.
- Serial trống hoặc không khớp tem / BIOS.
- Màn nhiều điểm chết, hở sáng nặng, ố lớn; rao FHD mà màn gốc là HD.
- Máy tụt xung mạnh, nóng tự sập, quạt kêu to.
- Bản lề lỏng/gãy, ốc toét nhiều, mùi khét, dấu hiệu vào nước.

## 💡 Mẹo trả giá
Mở `BaoCao.html`: phần **"Cần hỏi người bán / dùng để trả giá"** đã gom sẵn các mục vàng và đỏ.
Mỗi mục là một lý do giảm giá: pin chai, RAM một thanh (phải mua thêm), SSD hao mòn, thiếu đèn phím…
