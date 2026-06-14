import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../injection_container.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String locale;
  final bool autoConnect;
  final bool killSwitch;
  final bool dnsProtection;
  final bool ipv6Protection;
  final bool systemProxy;
  final bool tunMode;
  final bool autoStart;
  final bool minimizeToTray;
  final String dnsServers;
  final int autoUpdateInterval;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = 'en',
    this.autoConnect = false,
    this.killSwitch = false,
    this.dnsProtection = true,
    this.ipv6Protection = true,
    this.systemProxy = true,
    this.tunMode = false,
    this.autoStart = false,
    this.minimizeToTray = true,
    this.dnsServers = '1.1.1.1, 8.8.8.8',
    this.autoUpdateInterval = 6,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? locale,
    bool? autoConnect,
    bool? killSwitch,
    bool? dnsProtection,
    bool? ipv6Protection,
    bool? systemProxy,
    bool? tunMode,
    bool? autoStart,
    bool? minimizeToTray,
    String? dnsServers,
    int? autoUpdateInterval,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      autoConnect: autoConnect ?? this.autoConnect,
      killSwitch: killSwitch ?? this.killSwitch,
      dnsProtection: dnsProtection ?? this.dnsProtection,
      ipv6Protection: ipv6Protection ?? this.ipv6Protection,
      systemProxy: systemProxy ?? this.systemProxy,
      tunMode: tunMode ?? this.tunMode,
      autoStart: autoStart ?? this.autoStart,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      dnsServers: dnsServers ?? this.dnsServers,
      autoUpdateInterval: autoUpdateInterval ?? this.autoUpdateInterval,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final FlutterSecureStorage _storage;

  SettingsNotifier({required FlutterSecureStorage storage})
      : _storage = storage,
        super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;

    try {
      final themeMode = await _storage.read(key: 'theme_mode') ?? 'system';
      final locale = await _storage.read(key: 'locale') ?? 'en';
      final autoConnect = await _storage.read(key: 'auto_connect') == 'true';
      final killSwitch = await _storage.read(key: 'kill_switch') == 'true';
      final dnsProtection = await _storage.read(key: 'dns_protection') != 'false';
      final ipv6Protection = await _storage.read(key: 'ipv6_protection') != 'false';
      final systemProxy = await _storage.read(key: 'system_proxy') != 'false';
      final tunMode = await _storage.read(key: 'tun_mode') == 'true';
      final autoStart = await _storage.read(key: 'auto_start') == 'true';
      final minimizeToTray = await _storage.read(key: 'minimize_to_tray') != 'false';
      final dnsServers = await _storage.read(key: 'dns_servers') ?? '1.1.1.1, 8.8.8.8';
      final autoUpdateInterval = int.tryParse(await _storage.read(key: 'auto_update_interval') ?? '6') ?? 6;

      if (!mounted) return;

      state = SettingsState(
        themeMode: themeMode == 'dark' ? ThemeMode.dark : themeMode == 'light' ? ThemeMode.light : ThemeMode.system,
        locale: locale,
        autoConnect: autoConnect,
        killSwitch: killSwitch,
        dnsProtection: dnsProtection,
        ipv6Protection: ipv6Protection,
        systemProxy: systemProxy,
        tunMode: tunMode,
        autoStart: autoStart,
        minimizeToTray: minimizeToTray,
        dnsServers: dnsServers,
        autoUpdateInterval: autoUpdateInterval,
      );
    } catch (e) {
      // Игнорируем ошибки загрузки
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final modeStr = mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system';
    await _storage.write(key: 'theme_mode', value: modeStr);
    if (mounted) state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(String locale) async {
    await _storage.write(key: 'locale', value: locale);
    if (mounted) state = state.copyWith(locale: locale);
  }

  Future<void> toggleAutoConnect() async {
    final value = !state.autoConnect;
    await _storage.write(key: 'auto_connect', value: value.toString());
    if (mounted) state = state.copyWith(autoConnect: value);
  }

  Future<void> toggleKillSwitch() async {
    final value = !state.killSwitch;
    await _storage.write(key: 'kill_switch', value: value.toString());
    if (mounted) state = state.copyWith(killSwitch: value);
  }

  Future<void> toggleDnsProtection() async {
    final value = !state.dnsProtection;
    await _storage.write(key: 'dns_protection', value: value.toString());
    if (mounted) state = state.copyWith(dnsProtection: value);
  }

  Future<void> toggleIpv6Protection() async {
    final value = !state.ipv6Protection;
    await _storage.write(key: 'ipv6_protection', value: value.toString());
    if (mounted) state = state.copyWith(ipv6Protection: value);
  }

  Future<void> toggleSystemProxy() async {
    final value = !state.systemProxy;
    await _storage.write(key: 'system_proxy', value: value.toString());
    if (mounted) state = state.copyWith(systemProxy: value);
  }

  Future<void> toggleTunMode() async {
    final value = !state.tunMode;
    await _storage.write(key: 'tun_mode', value: value.toString());
    if (mounted) state = state.copyWith(tunMode: value);
  }

  Future<void> toggleAutoStart() async {
    final value = !state.autoStart;
    await _storage.write(key: 'auto_start', value: value.toString());
    if (mounted) state = state.copyWith(autoStart: value);
  }

  Future<void> toggleMinimizeToTray() async {
    final value = !state.minimizeToTray;
    await _storage.write(key: 'minimize_to_tray', value: value.toString());
    if (mounted) state = state.copyWith(minimizeToTray: value);
  }

  Future<void> setDnsServers(String servers) async {
    await _storage.write(key: 'dns_servers', value: servers);
    if (mounted) state = state.copyWith(dnsServers: servers);
  }

  Future<void> setAutoUpdateInterval(int hours) async {
    await _storage.write(key: 'auto_update_interval', value: hours.toString());
    if (mounted) state = state.copyWith(autoUpdateInterval: hours);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(storage: sl.get<FlutterSecureStorage>());
});