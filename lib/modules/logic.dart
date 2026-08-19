// lib/modules/logic.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'native_bridge.dart';

final _logger = Logger('Logic');

class AppConfig {
  String apiKey = '';
  String engine = 'google'; // 'google', 'gemini'
  String targetLang = 'vi'; // 'vi', 'en', 'zh'
  String themeMode = 'dark'; // 'light', 'dark', 'system'
  bool enableTransparency = true;

  AppConfig();

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'engine': engine,
        'targetLang': targetLang,
        'themeMode': themeMode,
        'enableTransparency': enableTransparency,
      };

  void fromJson(Map<String, dynamic> json) {
    apiKey = json['apiKey'] ?? '';
    engine = json['engine'] ?? 'google';
    targetLang = json['targetLang'] ?? 'vi';
    themeMode = json['themeMode'] ?? 'dark';
    enableTransparency = json['enableTransparency'] ?? true;
  }
}

class TranslationLogic extends ChangeNotifier {
  late SharedPreferences _prefs;
  final AppConfig config = AppConfig();
  
  // Custom smart dictionary
  Map<String, String> dictionary = {};
  
  // Excel coordinate patching data: { "SheetName": { "A1": "Translation text" } }
  Map<String, Map<String, String>> excelPatches = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  TranslationLogic() {
    _init();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load configurations
      config.apiKey = _prefs.getString('apiKey') ?? '';
      config.engine = _prefs.getString('engine') ?? 'google';
      config.targetLang = _prefs.getString('targetLang') ?? 'vi';
      config.themeMode = _prefs.getString('themeMode') ?? 'dark';
      config.enableTransparency = _prefs.getBool('enableTransparency') ?? true;

      // Load dictionary
      await loadDictionary();
      
      // Load patches
      await loadPatches();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to initialize settings: $e');
    }
  }

  // Cập nhật cấu hình
  Future<void> updateConfig({
    String? apiKey,
    String? engine,
    String? targetLang,
    String? themeMode,
    bool? enableTransparency,
  }) async {
    if (apiKey != null) {
      config.apiKey = apiKey;
      await _prefs.setString('apiKey', apiKey);
    }
    if (engine != null) {
      config.engine = engine;
      await _prefs.setString('engine', engine);
    }
    if (targetLang != null) {
      config.targetLang = targetLang;
      await _prefs.setString('targetLang', targetLang);
    }
    if (themeMode != null) {
      config.themeMode = themeMode;
      await _prefs.setString('themeMode', themeMode);
    }
    if (enableTransparency != null) {
      config.enableTransparency = enableTransparency;
      await _prefs.setBool('enableTransparency', enableTransparency);
    }
    notifyListeners();
  }

  // --- QUẢN LÝ TỪ ĐIỂN (DICTIONARY) ---

  Future<File> _getDictionaryFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'dictionary.json'));
  }

  Future<void> loadDictionary() async {
    try {
      final file = await _getDictionaryFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> decoded = json.decode(content);
        dictionary = decoded.map((key, value) => MapEntry(key, value.toString()));
      } else {
        // Khởi tạo từ điển mặc định của ứng dụng SOP
        dictionary = {
          "站位": "Vị trí thao tác",
          "作业步骤": "Các bước thực hiện",
          "注意事项": "Hạng mục chú ý",
          "设备": "Thiết bị",
          "工具": "Công cụ",
          "物料": "Vật liệu",
          "判定": "Đánh giá/Phán định",
          "备注": "Ghi chú",
          "确认": "Xác nhận",
          "日期": "Ngày tháng",
        };
        await saveDictionary();
      }
    } catch (e) {
      _logger.severe('Failed to load dictionary: $e');
    }
  }

  Future<void> saveDictionary() async {
    try {
      final file = await _getDictionaryFile();
      await file.writeAsString(json.encode(dictionary), flush: true);
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to save dictionary: $e');
    }
  }

  Future<void> addDictionaryEntry(String key, String value) async {
    dictionary[key.trim()] = value.trim();
    await saveDictionary();
  }

  Future<void> removeDictionaryEntry(String key) async {
    dictionary.remove(key);
    await saveDictionary();
  }

  Future<void> clearDictionary() async {
    dictionary.clear();
    await saveDictionary();
  }

  // --- QUẢN LÝ VÁ LỖI TỌA ĐỘ (PATCHES) ---

  Future<File> _getPatchesFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'excel_patches.json'));
  }

  Future<void> loadPatches() async {
    try {
      final file = await _getPatchesFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> decoded = json.decode(content);
        excelPatches = decoded.map((key, value) {
          final Map<String, dynamic> innerMap = value;
          return MapEntry(key, innerMap.map((k, v) => MapEntry(k, v.toString())));
        });
      } else {
        excelPatches = {};
        await savePatches();
      }
    } catch (e) {
      _logger.severe('Failed to load patches: $e');
    }
  }

  Future<void> savePatches() async {
    try {
      final file = await _getPatchesFile();
      await file.writeAsString(json.encode(excelPatches), flush: true);
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to save patches: $e');
    }
  }

  Future<void> addPatch(String sheet, String cell, String translation) async {
    if (!excelPatches.containsKey(sheet)) {
      excelPatches[sheet] = {};
    }
    excelPatches[sheet]![cell.trim().toUpperCase()] = translation.trim();
    await savePatches();
  }

  Future<void> removePatch(String sheet, String cell) async {
    if (excelPatches.containsKey(sheet)) {
      excelPatches[sheet]!.remove(cell.trim().toUpperCase());
      if (excelPatches[sheet]!.isEmpty) {
        excelPatches.remove(sheet);
      }
      await savePatches();
    }
  }

  // --- NGHIỆP VỤ DỊCH THUẬT (TRANSLATION SERVICES) ---

  /// Dịch văn bản thuần trực tiếp
  Future<String> translateText(String text, {String? sourceLang, String? targetLang}) async {
    final tLang = targetLang ?? config.targetLang;
    final sLang = sourceLang ?? 'auto';
    if (config.engine == 'gemini' && config.apiKey.isNotEmpty) {
      return await nativeAgent.translateTextGemini(text, tLang, config.apiKey, sourceLang: sLang);
    } else {
      return await nativeAgent.translateTextFree(text, tLang, sourceLang: sLang);
    }
  }

  /// Dịch tệp tài liệu (.xlsx, .docx, .txt)
  Future<Map<String, dynamic>> translateFile({
    required String srcPath,
    required String destPath,
    String? targetLang,
  }) async {
    final ext = p.extension(srcPath).toLowerCase();
    final tLang = targetLang ?? config.targetLang;
    
    if (ext == '.xlsx') {
      return await nativeAgent.engine.translateExcel(
        srcPath: srcPath,
        destPath: destPath,
        dictionary: dictionary,
        patches: excelPatches,
        engine: config.engine,
        apiKey: config.apiKey,
        targetLang: tLang,
      );
    } else if (ext == '.docx') {
      return await nativeAgent.engine.translateDocx(
        srcPath: srcPath,
        destPath: destPath,
        dictionary: dictionary,
        engine: config.engine,
        apiKey: config.apiKey,
        targetLang: tLang,
      );
    } else if (ext == '.pdf') {
      return await nativeAgent.engine.translatePdf(
        srcPath: srcPath,
        destPath: destPath,
        dictionary: dictionary,
        engine: config.engine,
        apiKey: config.apiKey,
        targetLang: tLang,
      );
    } else if (ext == '.pptx') {
      return await nativeAgent.engine.translatePptx(
        srcPath: srcPath,
        destPath: destPath,
        dictionary: dictionary,
        engine: config.engine,
        apiKey: config.apiKey,
        targetLang: tLang,
      );
    } else if (ext == '.txt') {
      return await _translateTextFile(srcPath, destPath, targetLang: tLang);
    } else {
      return {'success': false, 'error': 'Định dạng file $ext không hỗ trợ.'};
    }
  }

  /// Dịch file text đơn giản bằng Dart
  Future<Map<String, dynamic>> _translateTextFile(String srcPath, String destPath, {String? targetLang}) async {
    try {
      final file = File(srcPath);
      final lines = await file.readAsLines();
      final translatedLines = <String>[];
      
      int translatedCount = 0;
      for (var line in lines) {
        if (line.trim().isEmpty) {
          translatedLines.add('');
          continue;
        }
        
        // Xem có khớp hoàn toàn từ điển không
        final trimmed = line.trim();
        final lower = trimmed.toLowerCase();
        if (dictionary.containsKey(lower)) {
          translatedLines.add(dictionary[lower]!);
          translatedCount++;
          continue;
        }
        
        // Dịch online
        try {
          final trans = await translateText(trimmed, targetLang: targetLang);
          translatedLines.add(trans);
          translatedCount++;
        } catch (_) {
          translatedLines.add(line); // Giữ nguyên nếu dịch lỗi
        }
      }
      
      final destFile = File(destPath);
      await destFile.writeAsString(translatedLines.join('\n'), flush: true);
      
      return {
        'success': true,
        'total_translated': translatedCount,
        'remaining_chinese_count': 0,
        'remaining_cells': []
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi dịch file text: $e'};
    }
  }

  /// Dịch ảnh: OCR trích xuất chữ -> Dịch chữ
  Future<Map<String, dynamic>> translateImage(String imagePath, {String? targetLang}) async {
    // 1. Thực hiện OCR nhận chữ
    final ocrRes = await nativeAgent.engine.performOCR(imagePath: imagePath);
    if (ocrRes['success'] != true) {
      return ocrRes; // Trả về lỗi
    }

    final fullText = ocrRes['text'] as String? ?? '';
    final linesList = ocrRes['lines'] as List? ?? [];
    
    if (fullText.trim().isEmpty) {
      return {
        'success': true,
        'text': '',
        'translated_text': 'Không tìm thấy chữ trong ảnh.',
        'lines': []
      };
    }

    // 2. Dịch toàn bộ văn bản
    String translatedFullText = '';
    try {
      translatedFullText = await translateText(fullText, targetLang: targetLang);
    } catch (e) {
      translatedFullText = 'Lỗi dịch thuật: $e';
    }

    // 3. Dịch từng dòng riêng lẻ để hiển thị chi tiết vị trí nếu cần
    final translatedLines = <Map<String, dynamic>>[];
    for (var lineItem in linesList) {
      final lineText = lineItem['text'] as String? ?? '';
      String translatedLineText = '';
      if (lineText.trim().isNotEmpty) {
        // Dịch dòng
        try {
          // Thử tra từ điển trước
          final trimmed = lineText.trim();
          final lower = trimmed.toLowerCase();
          if (dictionary.containsKey(lower)) {
            translatedLineText = dictionary[lower]!;
          } else {
            translatedLineText = await translateText(trimmed, targetLang: targetLang);
          }
        } catch (_) {
          translatedLineText = lineText;
        }
      }
      translatedLines.add({
        'text': lineText,
        'translated': translatedLineText,
        'words': lineItem['words']
      });
    }

    return {
      'success': true,
      'text': fullText,
      'translated_text': translatedFullText,
      'lines': translatedLines
    };
  }
}
