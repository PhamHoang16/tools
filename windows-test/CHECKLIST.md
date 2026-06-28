# ✅ Checklist test laptop cũ (làm THỦ CÔNG tại chỗ)

> Script `Test-LaptopCu.ps1` lo phần tự động (pin, ổ cứng, RAM, bản quyền...).
> File này là những thứ **máy không tự kiểm tra được** — bạn phải tự soi/bấm/nghe.
> In ra hoặc mở trên điện thoại, tick từng mục khi đi xem máy.

---

## 0. Trước khi tới (mang theo)
- [ ] USB chứa cả thư mục `windows-test` (để chạy script + mở screen-test.html).
- [ ] Tai nghe (test jack 3.5mm + chất âm).
- [ ] Chuột USB (test cổng USB + đề phòng touchpad lỗi).
- [ ] Điện thoại có đèn flash (soi điểm chết, soi khe/ốc).
- [ ] Sạc của máy (xem có đúng zin, test cắm sạc nhận điện không).

---

## 1. Ngoại hình & khung máy
- [ ] Vỏ: móp, nứt, trầy nặng? Ốc vít có bị toét (đã mở máy nhiều)?
- [ ] **Bản lề**: gập mở êm, không kêu rắc, không gãy/ọp ẹp. Mở 1 tay được không.
- [ ] Khe tản nhiệt: bụi, dấu hiệu bung keo, mùi khét.
- [ ] Tem niêm phong / tem bảo hành còn không (nếu quan trọng với bạn).
- [ ] Logo, tem serial ở đáy máy **khớp** với serial script in ra (mục "Serial Number").

## 2. Màn hình (mở `screen-test.html` — bấm F11 full màn hình)
- [ ] **Điểm chết / điểm kẹt màu**: soi kỹ từng nền đỏ/lục/lam/trắng/đen.
- [ ] **Hở sáng (backlight bleed)**: nền đen, soi 4 mép & góc có loang sáng không.
- [ ] **Ố / đốm / ngả vàng**: nền trắng có vùng tối màu, vết ố nước.
- [ ] **Đốm/xước mặt kính**, lớp chống chói bong tróc.
- [ ] Độ sáng kéo max có đủ sáng không (màn cũ hay tối). Chỉnh độ sáng có ăn.
- [ ] Cảm ứng (nếu máy có): vuốt thử khắp màn hình.

## 3. Bàn phím & Touchpad
- [ ] Mở Notepad hoặc trang web **keyboard-test.space** (nếu có mạng) — **gõ đủ từng phím**, không phím nào liệt/double.
- [ ] Phím chức năng Fn: tăng/giảm sáng, âm lượng, tắt mic/wifi, đèn phím.
- [ ] **Đèn nền bàn phím** (nếu có) sáng đều.
- [ ] Touchpad: di mượt khắp bề mặt, click trái/phải, cuộn 2 ngón, không nhảy lung tung.

## 4. Loa, Mic, Webcam
- [ ] **Loa**: mở 1 bài nhạc / YouTube — nghe cả 2 bên trái-phải, không rè/méo, kéo to không vỡ tiếng.
- [ ] **Jack tai nghe**: cắm tai nghe, nghe có tiếng, không sột soạt.
- [ ] **Mic + Webcam**: mở app **Camera** của Windows + ghi âm thử (Voice Recorder). Hình rõ, tiếng thu được.

## 5. Cổng kết nối (test TỪNG cổng)
- [ ] Tất cả cổng **USB-A**: cắm chuột/USB, đảo qua từng cổng xem có nhận.
- [ ] Cổng **USB-C / Thunderbolt**: cắm thử thiết bị (sạc/USB-C) nếu có.
- [ ] **HDMI / xuất hình**: cắm ra màn ngoài/TV nếu test được.
- [ ] Khe **thẻ nhớ SD** (nếu có): cắm thẻ.
- [ ] **Cổng sạc**: cắm sạc — icon pin báo "đang sạc", không chập chờn khi lay dây.

## 6. Kết nối không dây
- [ ] **WiFi**: kết nối 1 mạng (phát 4G từ điện thoại), mở web — tốc độ ổn, không rớt.
- [ ] **Bluetooth**: bật, dò thấy điện thoại / tai nghe BT.

## 7. Nhiệt độ & quạt (chạy ~5-10 phút)
- [ ] Mở vài tab web + 1 video 1080p, để máy chạy vài phút.
- [ ] **Quạt**: nghe có quay không, có tiếng lạ (vòng bi khô) không.
- [ ] Sờ thân máy/bàn phím: nóng bất thường không. Máy có tự sập nguồn (quá nhiệt) không.
- [ ] (Tuỳ chọn) Cài **HWMonitor / HWiNFO** xem nhiệt độ CPU lúc tải.

## 8. Pin thực tế (nếu có thời gian)
- [ ] Rút sạc, dùng máy bình thường ~10 phút, xem % tụt nhanh bất thường không.
- [ ] Xem lại `BatteryReport.html` (script đã tạo trên Desktop): mục **Battery capacity history** và **Battery life estimates**.

---

## 🚩 Dấu hiệu NÊN BỎ QUA / TRẢ GIÁ MẠNH
- Pin sức khoẻ < 60% hoặc không nhận pin.
- Ổ cứng/SSD báo **Warning/Unhealthy**, hoặc tuổi thọ SSD còn < 50%.
- Màn nhiều điểm chết / hở sáng nặng / ố lớn.
- Máy nóng nhanh, tự sập nguồn, quạt kêu to.
- Bản lề lỏng/gãy, ốc toét (đã sửa nhiều), có mùi khét.
- Windows không kích hoạt **và** người bán không giải thích được nguồn gốc máy.
- Serial trên máy không khớp / đã bị xoá.

## 💡 Mẹo trả giá
Mỗi lỗi (pin chai, thiếu cổng, xước màn) đều là cớ để **thương lượng giảm giá**.
Ghi lại các mục ⚠️ và ❌ từ kết quả script để làm bằng chứng khi mặc cả.
