// lib/modules/native/win_core.dart
import 'dart:convert';
import '../native_bridge.dart';
import '../utils.dart';

class WindowsNativeEngine implements NativeEngine {
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
    final scriptPath = await NativeBridge.getScriptPath('excel_translator.py');
    final dictJson = json.encode(dictionary);
    final patchesJson = json.encode(patches);

    final res = await runCommand('python', [
      scriptPath,
      '--src', srcPath,
      '--dest', destPath,
      '--dict', dictJson,
      '--patches', patchesJson,
      '--engine', engine,
      '--key', apiKey,
      '--lang', targetLang
    ]);

    if (res.exitCode == 0) {
      try {
        return json.decode(res.stdout.toString().trim()) as Map<String, dynamic>;
      } catch (e) {
        return {'success': false, 'error': 'Failed to parse JSON from Python stdout: $e\nStdout: ${res.stdout}'};
      }
    } else {
      return {'success': false, 'error': 'Python error: ${res.stderr}\nStdout: ${res.stdout}'};
    }
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
    final scriptPath = await NativeBridge.getScriptPath('docx_translator.py');
    final dictJson = json.encode(dictionary);

    final res = await runCommand('python', [
      scriptPath,
      '--src', srcPath,
      '--dest', destPath,
      '--dict', dictJson,
      '--engine', engine,
      '--key', apiKey,
      '--lang', targetLang
    ]);

    if (res.exitCode == 0) {
      try {
        return json.decode(res.stdout.toString().trim()) as Map<String, dynamic>;
      } catch (e) {
        return {'success': false, 'error': 'Failed to parse JSON from Python stdout: $e\nStdout: ${res.stdout}'};
      }
    } else {
      return {'success': false, 'error': 'Python error: ${res.stderr}\nStdout: ${res.stdout}'};
    }
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
    final scriptPath = await NativeBridge.getScriptPath('pdf_translator.py');
    final dictJson = json.encode(dictionary);

    final res = await runCommand('python', [
      scriptPath,
      '--src', srcPath,
      '--dest', destPath,
      '--dict', dictJson,
      '--engine', engine,
      '--key', apiKey,
      '--lang', targetLang
    ]);

    if (res.exitCode == 0) {
      try {
        return json.decode(res.stdout.toString().trim()) as Map<String, dynamic>;
      } catch (e) {
        return {'success': false, 'error': 'Failed to parse JSON from Python stdout: $e\nStdout: ${res.stdout}'};
      }
    } else {
      return {'success': false, 'error': 'Python error: ${res.stderr}\nStdout: ${res.stdout}'};
    }
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
    final scriptPath = await NativeBridge.getScriptPath('pptx_translator.py');
    final dictJson = json.encode(dictionary);

    final res = await runCommand('python', [
      scriptPath,
      '--src', srcPath,
      '--dest', destPath,
      '--dict', dictJson,
      '--engine', engine,
      '--key', apiKey,
      '--lang', targetLang
    ]);

    if (res.exitCode == 0) {
      try {
        return json.decode(res.stdout.toString().trim()) as Map<String, dynamic>;
      } catch (e) {
        return {'success': false, 'error': 'Failed to parse JSON from Python stdout: $e\nStdout: ${res.stdout}'};
      }
    } else {
      return {'success': false, 'error': 'Python error: ${res.stderr}\nStdout: ${res.stdout}'};
    }
  }

  @override
  Future<Map<String, dynamic>> performOCR({required String imagePath}) async {
    final scriptPath = await NativeBridge.getScriptPath('win_ocr.ps1');
    final res = await runCommand('powershell', [
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-File', scriptPath,
      '-ImagePath', imagePath
    ]);

    if (res.exitCode == 0) {
      try {
        return json.decode(res.stdout.toString().trim()) as Map<String, dynamic>;
      } catch (e) {
        return {'success': false, 'error': 'Failed to parse JSON from PowerShell: $e\nStdout: ${res.stdout}'};
      }
    } else {
      return {'success': false, 'error': 'PowerShell OCR error: ${res.stderr}\nStdout: ${res.stdout}'};
    }
  }
}
