# AnimeVsub iOS (iPhone 6 / iOS 12.0+)

Ứng dụng xem Anime bản quyền thuần UIKit dành riêng cho hệ điều hành iOS từ phiên bản **12.0 trở lên**, tương thích tối ưu cho các thiết bị như **iPhone 6**, **iPhone 6 Plus**, iPad mini 2/3, iPad Air... (giới hạn ở iOS 12.5.7) cho tới các dòng iPhone mới nhất.

---

## 🌟 Tính Năng Chính Của Ứng Dụng

1. **Trang Chủ (Home)**:
   - Banner đề xuất Anime nổi bật (tự động trượt banner).
   - Danh sách phim mới cập nhật, Anime đang hot, Anime theo mùa.
   - Thẻ hiển thị poster chất lượng cao, số tập mới nhất.

2. **Tìm Kiếm Nhanh & Gợi Ý Trực Tiếp (Live Search)**:
   - Tìm kiếm theo từ khoá với cơ chế debounce chống nghẽn mạng.
   - Gợi ý từ khoá và phim tương ứng ngay khi đang gõ.
   - Lưu trữ và quản lý lịch sử tìm kiếm gần đây.

3. **Chi Tiết Anime (Anime Details)**:
   - Thông tin chi tiết: Tên phim, điểm số, năm phát hành, thể loại, tóm tắt cốt truyện.
   - Lưới danh sách các tập phim trực quan.
   - Hỗ trợ chọn tập để xem trực tiếp hoặc tải về máy.

4. **Trình Phát Video Nâng Cao (Video Player - AVPlayer)**:
   - Phát luồng video trực tuyến HLS (`.m3u8`) và phát ngoại tuyến các file đã tải (`.ts`, `.mp4`).
   - Tự động nhận diện nếu tập phim đã tải về máy để ưu tiên phát từ ổ cứng (không tốn dung lượng 4G/Wifi).
   - Bộ điều khiển video: Nút Play/Pause, tua tiến / lùi 10 giây, thanh trượt thời gian mượt mà.
   - Tự động lưu tiến trình đang xem dở mỗi 5 giây.
   - Tuỳ chọn chuyển sang tập tiếp theo khi kết thúc.

5. **Trình Tải Xuống Chuyên Sâu - Khắc Phục Lỗi Treo 0% (HLS Segment Downloader)**:
   - Khắc phục triệt để lỗi treo 0% do `AVAssetDownloadTask` trên các luồng m3u8 bảo mật/chuyển hướng.
   - Bộ giải mã playlist HLS tự động bóc tách từng segment `.ts`, tải tuần tự có retry, ghi trực tiếp vào bộ nhớ cục bộ.
   - Hiển thị tiến độ % thời gian thực chính xác: `(segments đã tải / tổng segments) * 100%`.
   - Lưu trữ ngoại tuyến tại `Documents/Downloads/[chapterId].ts` cho phép phát ngay cả khi không có mạng Internet.

6. **Quản Lý Tải Về (Downloads Manager)**:
   - Hiển thị danh sách các tập phim đang tải và đã tải xong.
   - Xem offline một chạm trực tiếp từ danh sách tải về.
   - Vuốt sang trái để xoá tập phim hoặc bấm nút "Xoá hết" để giải phóng dung lượng máy.

7. **Lịch Sử Xem (Watch History)**:
   - Ghi nhớ các phim đã xem kèm tập gần nhất, thời gian dừng lại và thanh hiển thị % tiến độ xem.
   - Bấm vào phim để tiếp tục xem ngay đoạn đang dở.
   - Vuốt để xoá lịch sử xem từng mục hoặc xoá toàn bộ lịch sử.

8. **Cài Đặt Ứng Dụng (Settings)**:
   - Tự động phát tiếp tập tiếp theo (Auto Next).
   - Tuỳ chỉnh thời gian tua nhanh (Double tap skip: 5s, 10s, 15s, 20s, 30s).
   - Xoá lịch sử xem & xoá lịch sử tìm kiếm.
   - Dọn dẹp bộ nhớ đệm (Cache Image).
   - Hiển thị thông tin phiên bản ứng dụng (Version 1.0.0).

---

## 🛠 Yêu Cầu Kỹ Thuật

- **Hệ điều hành**: iOS 12.0 trở lên (Hỗ trợ tốt nhất cho iPhone 6, iOS 12.5.7).
- **Kiến trúc ứng dụng**: Thuần **UIKit** (Không dùng SwiftUI để đảm bảo tương thích 100% với iOS 12).
- **Ngôn ngữ**: Swift 5.0.
- **Phụ thuộc bên ngoài**: 0 dependencies (100% Native Foundation, UIKit, AVFoundation).

---

## 📦 Hướng Dẫn Cài Đặt File `.ipa`

File `.ipa` xuất ra là bản **Unsigned** (không yêu cầu chứng chỉ Apple Developer trả phí):

1. **Đối với thiết bị đã Jailbreak**:
   - Cài đặt tweak **AppSync Unified** từ Cydia/Sileo.
   - Mở file `.ipa` qua ứng dụng **Filza File Manager** và nhấn `Install`, hoặc cài qua **iMazing / 3uTools**.
2. **Đối với thiết bị chưa Jailbreak**:
   - Sử dụng công cụ **AltStore**, **Sideloadly**, hoặc **TrollStore** (nếu máy trong dải phiên bản hỗ trợ TrollStore) để ký chứng chỉ cá nhân miễn phí và cài đặt vào máy.
