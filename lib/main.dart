import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDir.path);
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light, systemNavigationBarColor: Colors.transparent, systemNavigationBarIconBrightness: Brightness.light));
  await di.sl.init();

  runApp(EasyLocalization(supportedLocales: const [Locale('en'), Locale('ru'), Locale('zh'), Locale('fa')], path: 'assets/translations', fallbackLocale: const Locale('en'), child: const ProviderScope(child: EclipseApp())));
}