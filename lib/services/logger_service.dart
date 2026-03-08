import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static late final Logger logger;
  static File? _logFile;

  static Future<void> init() async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app_log.txt');

      logger = Logger(
        printer: PrettyPrinter(
          methodCount: 1,
          errorMethodCount: 5,
          lineLength: 80,
          colors: true,
          printEmojis: true,
          printTime: true,
        ),
        output: MultiOutput([ConsoleOutput(), FileOutput(file: _logFile!)]),
      );
      
      logger.i("Logger initialized. Saving logs to ${_logFile!.path}");

    } catch (e) {
      // Fallback to console-only logger if file system fails
      logger = Logger(
        printer: PrettyPrinter(),
        output: ConsoleOutput(),
      );
      logger.e("Failed to initialize file logger: $e. Using console logger only.");
    }
  }
}
