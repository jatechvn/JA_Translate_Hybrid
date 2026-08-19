// lib/modules/logger_config.dart
import 'dart:developer' as developer;
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final _logger = Logger('LoggerConfig');

Future<void> initLogger() async {
  // Set default level
  Logger.root.level = Level.ALL;

  // Listen to log events
  Logger.root.onRecord.listen((record) {
    // Print to developer console
    developer.log(
      record.message,
      time: record.time,
      sequenceNumber: record.sequenceNumber,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );

    // Print to stdout
    print('${record.time.toIso8601String()} [${record.level.name}] [${record.loggerName}]: ${record.message}');
  });

  // Attempt to set up a log file in the local logs folder
  try {
    final Directory appDocDir = await getApplicationSupportDirectory();
    final String logsDirPath = p.join(appDocDir.path, 'logs');
    final Directory logsDir = Directory(logsDirPath);
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    final File logFile = File(p.join(logsDirPath, '$dateStr.log'));

    Logger.root.onRecord.listen((record) async {
      try {
        final logMsg = '${record.time.toIso8601String()} [${record.level.name}] [${record.loggerName}]: ${record.message}\n';
        if (record.error != null) {
          await logFile.writeAsString('${logMsg}Error: ${record.error}\n${record.stackTrace ?? ""}\n', mode: FileMode.append, flush: true);
        } else {
          await logFile.writeAsString(logMsg, mode: FileMode.append, flush: true);
        }
      } catch (_) {}
    });

    _logger.info('Logging initialized. Log file path: ${logFile.path}');
  } catch (e) {
    _logger.warning('Failed to initialize file logging: $e');
  }
}
