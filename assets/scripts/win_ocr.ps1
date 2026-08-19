[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ImagePath
)

# Thiết lập Output Encoding thành UTF8 để giữ nguyên chữ Unicode (tiếng Trung, tiếng Việt...)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

try {
    # Load các WinRT Classes cần thiết
    [Windows.Security.Cryptography.CryptographicBuffer, Windows.Security.Cryptography, ContentType = WindowsRuntime] | Out-Null
    [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime] | Out-Null
    [Windows.Media.Ocr.OcrEngine, Windows.Media.Ocr, ContentType = WindowsRuntime] | Out-Null
    [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
    [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage, ContentType = WindowsRuntime] | Out-Null

    # Đảm bảo đường dẫn tuyệt đối
    $AbsoluteImagePath = [System.IO.Path]::GetFullPath($ImagePath)

    if (-not (Test-Path $AbsoluteImagePath)) {
        throw "Không tìm thấy file ảnh: $AbsoluteImagePath"
    }

    # Đọc file ảnh dưới dạng StorageFile của WinRT
    $asyncOperation = [Windows.Storage.StorageFile]::GetFileFromPathAsync($AbsoluteImagePath)
    $storageFile = $asyncOperation.GetAwaiter().GetResult()

    $asyncOpen = $storageFile.OpenAsync([Windows.Storage.FileAccessMode]::Read)
    $randomAccessStream = $asyncOpen.GetAwaiter().GetResult()

    # Giải mã hình ảnh sang SoftwareBitmap
    $asyncDecode = [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($randomAccessStream)
    $decoder = $asyncDecode.GetAwaiter().GetResult()

    $asyncSoftwareBitmap = $decoder.GetSoftwareBitmapAsync()
    $softwareBitmap = $asyncSoftwareBitmap.GetAwaiter().GetResult()

    # Khởi tạo OCR Engine (ưu tiên theo ngôn ngữ hệ thống của User)
    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
    if ($null -eq $engine) {
        # Nếu không lấy được ngôn ngữ User, thử khởi tạo với ngôn ngữ Tiếng Trung (zh-CN) hoặc Tiếng Anh (en-US)
        $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new("zh-CN"))
    }
    if ($null -eq $engine) {
        $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new("en-US"))
    }

    if ($null -eq $engine) {
        throw "Không thể khởi tạo Windows OCR Engine."
    }

    # Thực hiện OCR nhận diện văn bản
    $asyncResult = $engine.RecognizeAsync($softwareBitmap)
    $ocrResult = $asyncResult.GetAwaiter().GetResult()

    # Đóng stream hình ảnh để giải phóng bộ nhớ
    $randomAccessStream.Close()

    # Duyệt qua các dòng và từ để lấy văn bản & tọa độ
    $lines = @()
    foreach ($line in $ocrResult.Lines) {
        $lineText = $line.Text
        $words = @()
        foreach ($word in $line.Words) {
            $words += @{
                "text" = $word.Text
                "x" = $word.BoundingRect.X
                "y" = $word.BoundingRect.Y
                "width" = $word.BoundingRect.Width
                "height" = $word.BoundingRect.Height
            }
        }
        $lines += @{
            "text" = $lineText
            "words" = $words
        }
    }

    $response = @{
        "success" = $true
        "text" = $ocrResult.Text
        "lines" = $lines
    }

    # Xuất kết quả định dạng JSON UTF-8
    Write-Output (ConvertTo-Json $response -Depth 10)
}
catch {
    $response = @{
        "success" = $false
        "error" = $_.Exception.Message
    }
    Write-Output (ConvertTo-Json $response)
    exit 1
}
