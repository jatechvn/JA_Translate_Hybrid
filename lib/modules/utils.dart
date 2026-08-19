// lib/modules/utils.dart
import 'dart:io';
import 'package:logging/logging.dart';

final _logger = Logger('Utils');

/// Check if the OS is Windows 11 or newer (Build 22000+)
bool isWindows11OrNewer() {
  if (!Platform.isWindows) return false;
  try {
    final versionStr = Platform.operatingSystemVersion;
    final match = RegExp(r'Build\s+(\d+)').firstMatch(versionStr);
    if (match != null) {
      final buildNumber = int.tryParse(match.group(1) ?? '') ?? 0;
      return buildNumber >= 22000;
    }
  } catch (e) {
    _logger.warning('Failed to parse Windows version: $e');
  }
  return false;
}

/// Helper to run a command and return stdout/stderr
Future<ProcessResult> runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  _logger.info('Running command: $executable ${arguments.join(" ")}');
  try {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: Platform.isWindows,
    );
    return result;
  } catch (e) {
    _logger.severe('Failed to run command $executable: $e');
    return ProcessResult(0, -1, '', 'Failed to run command: $e');
  }
}
