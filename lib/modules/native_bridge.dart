// lib/modules/native_bridge.dart
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'native/win_core.dart';
import 'native/mac_core.dart';
import 'native/linux_core.dart';

final _logger = Logger('NativeBridge');

abstract class NativeEngine {
  Future<Map<String, dynamic>> translateExcel({
    required String srcPath,
    required String destPath,
    required Map<String, String> dictionary,
    required Map<String, Map<String, String>> patches,
    required String engine,
    required String apiKey,
    required String targetLang,
  });

  Future<Map<String, dynamic>> translateDocx({
    required String srcPath,
    required String destPath,
    required Map<String, String> dictionary,
    required String engine,
    required String apiKey,
    required String targetLang,
  });

  Future<Map<String, dynamic>> translatePdf({
    required String srcPath,
    required String destPath,
    required Map<String, String> dictionary,
    required String engine,
    required String apiKey,
    required String targetLang,
  });

  Future<Map<String, dynamic>> translatePptx({
    required String srcPath,
    required String destPath,
    required Map<String, String> dictionary,
    required String engine,
    required String apiKey,
    required String targetLang,
  });

  Future<Map<String, dynamic>> performOCR({required String imagePath});
}

class NativeBridge {
  final String osName;
  late NativeEngine engine;

  NativeBridge() : osName = Platform.operatingSystem {
    _initializeEngine();
  }

  void _initializeEngine() {
    if (Platform.isWindows) {
      engine = WindowsNativeEngine();
    } else if (Platform.isMacOS) {
      engine = MacNativeEngine();
    } else if (Platform.isLinux) {
      engine = LinuxNativeEngine();
    } else {
      engine = FallbackNativeEngine(osName);
    }
  }

  /// Resolve path of a script relative to development or production folders
  static Future<String> getScriptPath(String scriptName) async {
    // 1. Dev path
    final devFile = File('${Directory.current.path}/assets/scripts/$scriptName');
    if (await devFile.exists()) {
      return devFile.path;
    }

    // 2. Prod path
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final prodFile = File('$exeDir/data/flutter_assets/assets/scripts/$scriptName');
    if (await prodFile.exists()) {
      return prodFile.path;
    }

    // 3. MacOS bundle Resources path
    if (Platform.isMacOS) {
      final macOSFile = File('$exeDir/../Resources/flutter_assets/assets/scripts/$scriptName');
      if (await macOSFile.exists()) {
        return macOSFile.path;
      }
    }

    return devFile.path; // Fallback
  }

  /// Translate plain text using free Google Translate (pure Dart - fast!)
  Future<String> translateTextFree(String text, String targetLang, {String sourceLang = 'auto'}) async {
    if (text.trim().isEmpty) return '';
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sourceLang&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}'
      );
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final decoded = json.decode(responseBody);
        final List parts = decoded[0];
        final buffer = StringBuffer();
        for (var part in parts) {
          if (part != null && part.isNotEmpty) {
            buffer.write(part[0]);
          }
        }
        return buffer.toString();
      } else {
        throw Exception('Lỗi HTTP ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Text translation failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Translate plain text using Gemini API
  Future<String> translateTextGemini(String text, String targetLang, String apiKey, {String sourceLang = 'auto'}) async {
    if (text.trim().isEmpty) return '';
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'
      );
      final request = await client.postUrl(uri);
      request.headers.set('content-type', 'application/json');
      
      final sourceDesc = sourceLang == 'auto' ? 'ngôn ngữ tự động nhận diện' : 'ngôn ngữ mã "$sourceLang"';
      final prompt = 'Bạn là một biên dịch viên chuyên nghiệp. Hãy dịch đoạn văn bản sau đây từ $sourceDesc sang ngôn ngữ mã "$targetLang". Chỉ trả về bản dịch cuối cùng, tuyệt đối không thêm giải thích hay các từ dư thừa nào khác:\n\n$text';
      final body = json.encode({
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ]
      });
      request.write(body);
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final decoded = json.decode(responseBody);
        var translated = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
        translated = translated.trim();
        if (translated.startsWith('"') && translated.endsWith('"')) {
          translated = translated.substring(1, translated.length - 1);
        }
        return translated;
      } else {
        throw Exception('Lỗi Gemini API HTTP ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Gemini text translation failed: $e');
      rethrow;
    } finally {
      client.close();
    }
  }
}

class FallbackNativeEngine implements NativeEngine {
  final String os;
  FallbackNativeEngine(this.os);

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
    return {'success': false, 'error': 'Hệ điều hành $os không được hỗ trợ xử lý Excel.'};
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
    return {'success': false, 'error': 'Hệ điều hành $os không được hỗ trợ xử lý Word.'};
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
    return {'success': false, 'error': 'Hệ điều hành $os không được hỗ trợ xử lý PDF.'};
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
    return {'success': false, 'error': 'Hệ điều hành $os không được hỗ trợ xử lý PowerPoint.'};
  }

  @override
  Future<Map<String, dynamic>> performOCR({required String imagePath}) async {
    return {'success': false, 'error': 'Hệ điều hành $os không được hỗ trợ OCR.'};
  }
}

final nativeAgent = NativeBridge();
