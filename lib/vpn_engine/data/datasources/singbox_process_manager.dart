import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../../core/errors/exceptions.dart';

class SingBoxProcessManager {
  Process? _process;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;
  final StreamController<String> _logController = StreamController<String>.broadcast();
  final StreamController<SingBoxProcessState> _stateController = StreamController<SingBoxProcessState>.broadcast();
  SingBoxProcessState _currentState = SingBoxProcessState.stopped;
  bool get isRunning => _currentState == SingBoxProcessState.running;
  Stream<String> get logStream => _logController.stream;
  Stream<SingBoxProcessState> get stateStream => _stateController.stream;

  Future<void> start({required String binaryPath, required String configPath}) async {
    if (_currentState == SingBoxProcessState.running) await stop();
    try {
      _setState(SingBoxProcessState.starting);
      _process = await Process.start(
        binaryPath,
        ['run', '-c', configPath],
        environment: {
          ...Platform.environment,
          'ENABLE_DEPRECATED_LEGACY_DNS_SERVERS': 'true',
          'ENABLE_DEPRECATED_OUTBOUND_DNS_RULE_ITEM': 'true',
          'ENABLE_DEPRECATED_MISSING_DOMAIN_RESOLVER': 'true',
        },
      );
      _stdoutSub = _process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((l) => _logController.add(l));
      _stderrSub = _process!.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((l) => _logController.add(l));
      _process!.exitCode.then((c) { _logController.add('Exited: $c'); _disposeSubs(); _setState(SingBoxProcessState.stopped); });
      await Future.delayed(const Duration(milliseconds: 500));
      _setState(SingBoxProcessState.running);
    } catch (e) { _disposeSubs(); _setState(SingBoxProcessState.error); throw SingBoxProcessException(message: '$e'); }
  }

  Future<void> stop() async {
    if (_process == null) return;
    _setState(SingBoxProcessState.stopping);
    try { _process!.kill(ProcessSignal.sigterm); await _process!.exitCode.timeout(const Duration(seconds: 3)); } catch (_) { _process!.kill(ProcessSignal.sigkill); }
    _disposeSubs(); _setState(SingBoxProcessState.stopped);
  }

  void _disposeSubs() { _stdoutSub?.cancel(); _stderrSub?.cancel(); _stdoutSub = null; _stderrSub = null; _process = null; }
  void _setState(SingBoxProcessState s) { _currentState = s; if (!_stateController.isClosed) _stateController.add(s); }
  void dispose() { _disposeSubs(); _logController.close(); _stateController.close(); }
}

enum SingBoxProcessState { stopped, starting, running, stopping, error }

class SingBoxProcessException extends AppException {
  const SingBoxProcessException({required super.message, super.originalError, super.code = 'SINGBOX_PROCESS_ERROR'});
}