// lib/modules/native/mac_core.dart
import '../native_bridge.dart';

class MacNativeEngine implements NativeEngine {
  @override
  Future<Map<String, dynamic>> translateExcel({
    required String srcPath,
    required String destPath,
    required Map<String, String> dictionary,
    required Map<String, Map<String, String>> patches,
    required String engine,
    required String apiKey,
    required String targetLang,
  }) async {
    return {'success': false, 'error': 'Xử lý Excel chưa được hỗ trợ trên macOS'};
  }

  @override
  Future<Map<String, dynamic>> translateDocx({
    required String srcPath,
    required String destPath,
    required Map<String, String> dictionary,
    required String engine,
    required String apiKey,
    required String targetLang,
  }) async {
    return {'success': false, 'error': 'Xử lý Word chưa được hỗ trợ trên macOS'};
  }

  @override
  Future<Map<String, dynamic>> translatePdf({
    required String srcPath,
    required String destPath,
    required Map<String, String> dictionary,
    required String engine,
    required String apiKey,
    required String targetLang,
  }) async {
    return {'success': false, 'error': 'Xử lý PDF chưa được hỗ trợ trên macOS'};
  }

  @override
  Future<Map<String, dynamic>> translatePptx({
    required String srcPath,
    required String destPath,
    required Map<String, String> dictionary,
    required String engine,
    required String apiKey,
    required String targetLang,
  }) async {
    return {'success': false, 'error': 'Xử lý PowerPoint chưa được hỗ trợ trên macOS'};
  }

  @override
  Future<Map<String, dynamic>> performOCR({required String imagePath}) async {
    return {'success': false, 'error': 'OCR chưa được hỗ trợ trên macOS'};
  }
}
