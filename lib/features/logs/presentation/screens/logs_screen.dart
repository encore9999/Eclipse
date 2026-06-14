import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../vpn_engine/data/datasources/singbox_process_manager.dart';
import '../../../../injection_container.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _logSub;

  @override
  void initState() {
    super.initState();
    _logs.add('[${_time()}] Log viewer started');
    _logs.add('[${_time()}] Waiting for connection...');

    try {
      final pm = sl.get<SingBoxProcessManager>();
      _logSub = pm.logStream.listen((log) {
        setState(() {
          _logs.add('[${_time()}] $log');
          if (_logs.length > 500) _logs.removeAt(0);
        });
        _scrollToBottom();
      });
      _logs.add('[${_time()}] Listening to SingBox logs');
    } catch (e) {
      _logs.add('[${_time()}] ERROR: $e');
    }
  }

  String _time() => DateTime.now().toString().substring(11, 19);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyLogs() {
    final text = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied!')),
    );
  }

  void _addTestLog(String message) {
    setState(() {
      _logs.add('[${_time()}] $message');
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ? AppColors.backgroundGradient : [const Color(0xFFF8F7FF), const Color(0xFFF0EEFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Text('Logs', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    // Тестовые кнопки
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: 'Test info',
                      onPressed: () => _addTestLog('INFO: Test message'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.warning, size: 18, color: Colors.orange),
                      tooltip: 'Test warning',
                      onPressed: () => _addTestLog('WARN: Test warning'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.error, size: 18, color: Colors.red),
                      tooltip: 'Test error',
                      onPressed: () => _addTestLog('ERROR: Test error'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy logs',
                      onPressed: _copyLogs,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Clear',
                      onPressed: () => setState(() => _logs.clear()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF0D0D0D),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color color = Colors.greenAccent;
                      if (log.contains('ERROR') || log.contains('FATAL') || log.contains('error')) {
                        color = Colors.redAccent;
                      } else if (log.contains('WARN') || log.contains('warn')) {
                        color = Colors.orangeAccent;
                      } else if (log.contains('INFO') || log.contains('info')) {
                        color = Colors.cyanAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            color: color,
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}