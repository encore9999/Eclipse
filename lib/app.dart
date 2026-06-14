import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'main_shell.dart';

class EclipseApp extends ConsumerStatefulWidget {
  const EclipseApp({super.key});

  @override ConsumerState<EclipseApp> createState() => _EclipseAppState();
}

class _EclipseAppState extends ConsumerState<EclipseApp> {
  @override void initState() {
    super.initState();
    ref.listenManual(settingsProvider, (prev, next) {
      if (prev?.locale != next.locale) {
        context.setLocale(Locale(next.locale));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      
      title: 'Eclipse VPN',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const MainShell(),
    );
  }
}