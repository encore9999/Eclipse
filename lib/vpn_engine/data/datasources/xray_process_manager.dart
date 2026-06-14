import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

/// Менеджер процесса Xray-core
/// Отвечает за запуск, остановку и мониторинг
class XrayProcessManager {
  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final StreamController<String> _logController = StreamController<String>.broadcast();
  final StreamController<XrayProcessState> _stateController = StreamController<XrayProcessState>.broadcast();
  
  int? _pid;
  XrayProcessState _currentState = XrayProcessState.stopped;
  DateTime? _startTime;

  // ━━━━━━━ Геттеры ━━━━━━━

  bool get isRunning => _process != null && _currentState == XrayProcessState.running;
  int? get pid => _pid;
  XrayProcessState get currentState => _currentState;
  Stream<String> get logStream => _logController.stream;
  Stream<XrayProcessState> get stateStream => _stateController.stream;
  DateTime? get startTime => _startTime;

  // ━━━━━━━ Управление процессом ━━━━━━━

  /// Запустить Xray-core
  Future<void> start({
    required String binaryPath,
    required String configPath,
    List<String>? additionalArgs,
  }) async {
    if (isRunning) {
      throw XrayProcessException(message: 'Xray is already running');
    }

    // Проверяем существование бинарника
    final binaryFile = File(binaryPath);
    if (!await binaryFile.exists()) {
      throw XrayProcessException(message: 'Xray binary not found: $binaryPath');
    }

    // Проверяем конфиг
    final configFile = File(configPath);
    if (!await configFile.exists()) {
      throw XrayProcessException(message: 'Config file not found: $configPath');
    }

    // Аргументы запуска
    final args = <String>[
      'run',
      '-config', configPath,
      '-format', 'json',
    ];

    if (additionalArgs != null) {
      args.addAll(additionalArgs);
    }

    try {
      _updateState(XrayProcessState.starting);
      
      // Запускаем процесс
      _process = await Process.start(
        binaryPath,
        args,
        mode: ProcessStartMode.normal,
        environment: Platform.environment,
        workingDirectory: File(binaryPath).parent.path,
      );

      _pid = _process!.pid;
      _startTime = DateTime.now();

      // Слушаем stdout
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          _logController.add('[STDOUT] $line');
          _parseLogLine(line);
        },
        onError: (error) {
          _logController.add('[STDOUT ERROR] $error');
        },
      );

      // Слушаем stderr
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          _logController.add('[STDERR] $line');
          _parseLogLine(line);
        },
        onError: (error) {
          _logController.add('[STDERR ERROR] $error');
        },
      );

      // Ждём завершения процесса
      _process!.exitCode.then((exitCode) {
        _logController.add('Xray process exited with code: $exitCode');
        _cleanup();
        if (exitCode != 0 && _currentState != XrayProcessState.stopping) {
          _updateState(XrayProcessState.error);
        } else {
          _updateState(XrayProcessState.stopped);
        }
      });

      // Даём время на запуск
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_process != null) {
        _updateState(XrayProcessState.running);
      }
    } catch (e) {
      _cleanup();
      _updateState(XrayProcessState.error);
      throw XrayProcessException(
        message: 'Failed to start Xray: $e',
        originalError: e,
      );
    }
  }

  /// Остановить Xray-core
  Future<void> stop() async {
    if (_process == null) return;

    _updateState(XrayProcessState.stopping);

    try {
      // Отправляем SIGTERM
      _process!.kill(ProcessSignal.sigterm);

      // Ждём graceful shutdown
      final timeout = Future.delayed(const Duration(seconds: 5), () => 'timeout');
      final exitCode = await Future.any([
        _process!.exitCode.then((code) => 'exit:$code'),
        timeout,
      ]);

      if (exitCode == 'timeout') {
        // Принудительно убиваем
        _process!.kill(ProcessSignal.sigkill);
        _logController.add('Xray did not stop gracefully, sent SIGKILL');
      }
    } catch (e) {
      _logController.add('Error stopping Xray: $e');
    } finally {
      _cleanup();
      _updateState(XrayProcessState.stopped);
    }
  }

  /// Перезапустить Xray-core
  Future<void> restart({
    required String binaryPath,
    required String configPath,
    List<String>? additionalArgs,
  }) async {
    await stop();
    await Future.delayed(const Duration(seconds: 1));
    await start(
      binaryPath: binaryPath,
      configPath: configPath,
      additionalArgs: additionalArgs,
    );
  }

  // ━━━━━━━ Вспомогательные методы ━━━━━━━

  /// Парсинг логов для определения состояния
  void _parseLogLine(String line) {
    final lowerLine = line.toLowerCase();
    
    if (lowerLine.contains('started') || lowerLine.contains('listening')) {
      _updateState(XrayProcessState.running);
    } else if (lowerLine.contains('failed') || lowerLine.contains('fatal')) {
      // Не меняем состояние — просто логируем ошибку
      _logController.add('[PARSED ERROR] $line');
    } else if (lowerLine.contains('stopped') || lowerLine.contains('shutdown')) {
      _updateState(XrayProcessState.stopped);
    }
  }

  /// Обновление состояния процесса
  void _updateState(XrayProcessState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
    }
  }

  /// Очистка ресурсов процесса
  void _cleanup() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
    _process = null;
    _pid = null;
    _startTime = null;
  }

  /// Получить путь к бинарнику Xray для текущей платформы
  static Future<String> getDefaultBinaryPath() async {
    final appDir = await getApplicationSupportDirectory();
    
    if (Platform.isWindows) {
      return '${appDir.path}/xray/xray.exe';
    } else if (Platform.isMacOS) {
      return '${appDir.path}/xray/xray';
    } else if (Platform.isLinux) {
      return '${appDir.path}/xray/xray';
    }
    
    throw UnsupportedError('Unsupported platform');
  }

  /// Получить путь к конфигу по умолчанию
  static Future<String> getDefaultConfigPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/${AppConstants.xrayConfigFileName}';
  }

  /// Получить путь к лог-файлу
  static Future<String> getDefaultLogPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/${AppConstants.xrayLogFileName}';
  }

  /// Освобождение ресурсов
  void dispose() {
    _cleanup();
    _logController.close();
    _stateController.close();
  }
}

/// Состояние процесса Xray
enum XrayProcessState {
  stopped,
  starting,
  running,
  stopping,
  error,
}