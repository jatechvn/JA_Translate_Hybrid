# JA Translate Hybrid 🚀

JA Translate Hybrid là một ứng dụng máy tính (Desktop App) được thiết kế hiện đại, mượt mà bằng **Flutter** kết hợp sức mạnh xử lý file của **Python** và nhận diện hình ảnh offline bằng **Windows OCR** thông qua **PowerShell**. 

Ứng dụng chuyên dùng để dịch thuật các tài liệu SOP (Quy trình thao tác chuẩn), bản vẽ, biểu mẫu kỹ thuật tự động từ tiếng Trung/Anh sang tiếng Việt, giải quyết triệt để vấn đề mất định dạng (format) khi dịch thủ công.

---

## ✨ Tính Năng Nổi Bật

1. **Dịch Thuật Tài Liệu Chuyên Sâu**:
   - Dịch **Excel (.xlsx)**: Duyệt từng ô chứa chữ tiếng Trung/Anh, dịch tự động và bảo toàn 100% hình ảnh, màu nền, font chữ, đường viền, ô gộp (Merged Cells)...
   - Dịch **Word (.docx)** & **Text (.txt)**: Dịch các đoạn văn bản và bảng biểu nhưng giữ nguyên cấu trúc định dạng.
   - **Từ điển thông minh (Dictionary)**: Tra từ điển tùy chỉnh trước khi dịch tự động, đảm bảo dịch đúng các từ khóa kỹ thuật.
   - **Vá lỗi tọa độ (Coordinate patching)**: Chỉ định dịch đè nội dung chính xác lên tọa độ ô cụ thể.
   - **Quét kiểm tra chất lượng (Verification)**: Quét và hiển thị tọa độ các ô còn chữ tiếng Trung sau khi dịch xong.

2. **Dịch Văn Bản Song Song**:
   - Giao diện 2 cột nguồn - dịch trực quan, dịch tức thời với tốc độ cao.
   - Hỗ trợ dịch miễn phí (Nokey) hoặc dịch chất lượng cao qua Gemini AI.

3. **Dịch Hình Ảnh (OCR & Translate)**:
   - Trích xuất chữ tiếng Trung/Anh từ ảnh chụp bằng **Windows OCR Engine offline** được tích hợp sẵn trên hệ điều hành Windows.
   - Tự động dịch văn bản trích xuất được mà không cần kết nối mạng hay cài thêm thư viện ML nặng nề.

4. **Giao Diện Hiện Đại & Cao Cấp**:
   - Hỗ trợ hiệu ứng kính mờ **Glassmorphism (Mica/Acrylic)** mượt mà trên Windows 11.
   - Đồng bộ màu thanh tiêu đề Windows (Title bar) theo chủ đề Sáng/Tối lập tức, không gây giật lag.

---

## 🛠️ Cài Đặt & Chạy Ứng Dụng

### Yêu Cầu Hệ Thống:
- **Hệ điều hành**: Windows 10 hoặc Windows 11 (khuyến nghị Windows 11 để có trải nghiệm Mica đầy đủ).
- **Bộ công cụ**: [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (phiên bản 3.x).
- **Python**: Đã cài đặt Python 3.10+ cùng các thư viện:
  ```bash
  pip install openpyxl python-docx deep-translator requests
  ```

### Chạy chế độ Phát triển (Development):
Chạy tệp batch sau ở thư mục gốc:
```cmd
run.bat
```
Hoặc dùng lệnh Flutter:
```bash
flutter run -d windows
```

### Đóng gói Bản phát hành (Release):
Chạy tệp batch sau để biên dịch và tự động sao chép ứng dụng vào thư mục `dist/`:
```cmd
build.bat
```

---

## 📂 Cấu Trúc Dự Án
```text
JA_Translate_Hybrid/
├── assets/
│   └── scripts/
│       ├── excel_translator.py   # Script Python xử lý dịch Excel (.xlsx) bảo toàn định dạng
│       ├── docx_translator.py    # Script Python xử lý dịch Word (.docx) bảo toàn định dạng
│       └── win_ocr.ps1           # Script PowerShell thực thi Windows OCR offline
├── lib/
│   ├── main.dart                 # Hàm main, khởi tạo Window Manager và MultiProvider
│   └── modules/
│       ├── ui/
│       │   ├── main_window.dart  # Trình hiển thị giao diện 4 Tab chức năng
│       │   ├── styles.dart       # Quản lý Theme, Glassmorphism, Titlebar Channel
│       │   └── dialogs.dart      # Các cửa sổ điền thông tin (Từ điển, Vá lỗi ô)
│       ├── native/
│       │   ├── win_core.dart     # Engine tích hợp chạy script Python & PowerShell trên Windows
│       │   ├── mac_core.dart     # Stub macOS
│       │   └── linux_core.dart   # Stub Linux
│       ├── native_bridge.dart    # Cầu nối trung gian phát hiện OS và điều phối Engine
│       ├── logic.dart            # Quản lý nghiệp vụ chính, từ điển và cấu hình hệ thống
│       ├── utils.dart            # Các hàm tiện ích (phát hiện phiên bản OS, chạy tiến trình con)
│       └── constants.dart        # Định nghĩa các hằng số ứng dụng (appVersion, appName)
├── pubspec.yaml                  # Khai báo thư viện và tài nguyên assets/scripts/
├── run.bat                       # Tệp khởi động nhanh trên Windows
└── build.bat                     # Tệp đóng gói phát hành trên Windows
```
