import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isDark ? AppColors.backgroundGradient : [const Color(0xFFF8F7FF), const Color(0xFFF0EEFF)])),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(floating: true, backgroundColor: Colors.transparent, title: Text('settings'.tr(), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700))),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  _SectionTitle(title: 'appearance'.tr()),
                  const SizedBox(height: 8),
                  _SettingsCard(children: [
                    _ThemeSelector(currentMode: settings.themeMode, onChanged: (m) => ref.read(settingsProvider.notifier).setThemeMode(m)),
                    _Divider(),
                    _LanguageSelector(currentLocale: settings.locale, onChanged: (l) => ref.read(settingsProvider.notifier).setLocale(l)),
                  ]),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'connection'.tr()),
                  const SizedBox(height: 8),
                  _SettingsCard(children: [
                    _SwitchTile(icon: Icons.flash_on_rounded, title: 'auto_connect'.tr(), subtitle: 'auto_connect_desc'.tr(), value: settings.autoConnect, onChanged: (_) => ref.read(settingsProvider.notifier).toggleAutoConnect()),
                    _Divider(),
                    _SwitchTile(icon: Icons.wifi_find_rounded, title: 'system_proxy'.tr(), subtitle: 'system_proxy_desc'.tr(), value: settings.systemProxy, onChanged: (_) => ref.read(settingsProvider.notifier).toggleSystemProxy()),
                    _Divider(),
                    _SwitchTile(icon: Icons.vpn_lock_rounded, title: 'tun_mode'.tr(), subtitle: 'tun_mode_desc'.tr(), value: settings.tunMode, onChanged: (_) => ref.read(settingsProvider.notifier).toggleTunMode()),
                  ]),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'security'.tr()),
                  const SizedBox(height: 8),
                  _SettingsCard(children: [
                    _SwitchTile(icon: Icons.shield_moon_rounded, title: 'kill_switch'.tr(), subtitle: 'kill_switch_desc'.tr(), value: settings.killSwitch, onChanged: (_) => ref.read(settingsProvider.notifier).toggleKillSwitch()),
                    _Divider(),
                    _SwitchTile(icon: Icons.dns_outlined, title: 'dns_protection'.tr(), subtitle: 'dns_protection_desc'.tr(), value: settings.dnsProtection, onChanged: (_) => ref.read(settingsProvider.notifier).toggleDnsProtection()),
                    _Divider(),
                    _SwitchTile(icon: Icons.security_rounded, title: 'ipv6_protection'.tr(), subtitle: 'ipv6_protection_desc'.tr(), value: settings.ipv6Protection, onChanged: (_) => ref.read(settingsProvider.notifier).toggleIpv6Protection()),
                  ]),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'about'.tr()),
                  const SizedBox(height: 8),
                  _SettingsCard(children: [
                    _InfoTile(icon: Icons.info_outline_rounded, title: 'version'.tr(), subtitle: '1.0.0'),
                  ]),
                  const SizedBox(height: 32),
                ])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 4), child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary[400], fontWeight: FontWeight.w700, letterSpacing: 1.2)));
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightSurface), child: Column(children: children));
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 52, color: Theme.of(context).colorScheme.outline.withOpacity(0.15));
}

class _SwitchTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final bool value; final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [Icon(icon, color: AppColors.primary[400], size: 22), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))])), Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary[500])]));
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [Icon(icon, color: AppColors.primary[400], size: 22), const SizedBox(width: 14), Expanded(child: Text(title)), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontFamily: 'JetBrainsMono'))]));
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode currentMode; final ValueChanged<ThemeMode> onChanged;
  const _ThemeSelector({required this.currentMode, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [Icon(currentMode == ThemeMode.dark ? Icons.dark_mode_rounded : currentMode == ThemeMode.light ? Icons.light_mode_rounded : Icons.brightness_auto_rounded, color: AppColors.primary[400], size: 22), const SizedBox(width: 14), Expanded(child: Text('theme'.tr())), SegmentedButton<ThemeMode>(segments: [ButtonSegment(value: ThemeMode.system, label: Text('system'.tr(), style: const TextStyle(fontSize: 11))), ButtonSegment(value: ThemeMode.light, label: Text('light'.tr(), style: const TextStyle(fontSize: 11))), ButtonSegment(value: ThemeMode.dark, label: Text('dark'.tr(), style: const TextStyle(fontSize: 11)))], selected: {currentMode}, onSelectionChanged: (m) => onChanged(m.first))]));
}

class _LanguageSelector extends StatelessWidget {
  final String currentLocale; final ValueChanged<String> onChanged;
  const _LanguageSelector({required this.currentLocale, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [const Icon(Icons.translate_rounded, color: AppColors.primary, size: 22), const SizedBox(width: 14), Expanded(child: Text('language'.tr())), DropdownButton<String>(value: currentLocale, underline: const SizedBox(), items: const [DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')), DropdownMenuItem(value: 'ru', child: Text('🇷🇺 Русский')), DropdownMenuItem(value: 'zh', child: Text('🇨🇳 中文')), DropdownMenuItem(value: 'fa', child: Text('🇮🇷 فارسی'))], onChanged: (v) { if (v != null) onChanged(v); })]));
}