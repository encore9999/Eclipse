import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app.dart';
import 'injection_container.dart' as di;
import 'features/servers/domain/entities/server.dart';
import 'features/servers/domain/repositories/server_repository.dart';
import 'vpn_engine/domain/usecases/connect_vpn.dart';
import 'core/utils/result.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDir.path);
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await di.sl.init();

  // Квадратное окно
  await windowManager.ensureInitialized();
  windowManager.setSize(const Size(600, 600));
  windowManager.setResizable(false);
  windowManager.center();

  runApp(EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('ru'), Locale('zh'), Locale('fa')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: const ProviderScope(child: EclipseApp()),
  ));

  // Auto Connect
  const storage = FlutterSecureStorage();
  final autoConnect = await storage.read(key: 'auto_connect') == 'true';
  if (autoConnect) {
    await Future.delayed(const Duration(seconds: 2));
    final serverRepo = di.sl.get<ServerRepository>();
    final connectVpn = di.sl.get<ConnectVpn>();
    final serversResult = await serverRepo.getServers();
    if (serversResult is Success<List<Server>>) {
      final servers = (serversResult as Success<List<Server>>).data;
      if (servers.isNotEmpty) {
        servers.sort((a, b) => (a.ping ?? 9999).compareTo(b.ping ?? 9999));
        await connectVpn(servers.first);
      }
    }
  }
}