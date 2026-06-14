import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class UpdateService {
  static const String _repoUrl = 'https://api.github.com/repos/encore9999/Eclipse/releases/latest';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final dio = Dio();
      final response = await dio.get(_repoUrl);
      if (response.statusCode == 200) {
        final latestVersion = response.data['tag_name'].toString().replaceAll('v', '');
        final downloadUrl = response.data['html_url'];
        if (_isNewer(latestVersion, currentVersion)) {
          _showUpdateDialog(context, latestVersion, downloadUrl);
        }
      }
    } catch (e) { print('[Update] Check failed: $e'); }
  }

  static bool _isNewer(String latest, String current) {
    final lp = latest.split('.').map(int.parse).toList();
    final cp = current.split('.').map(int.parse).toList();
    for (int i = 0; i < lp.length; i++) {
      if (i >= cp.length) return true;
      if (lp[i] > cp[i]) return true;
      if (lp[i] < cp[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Available'),
        content: Text('New version $version available!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
          FilledButton(onPressed: () { launchUrl(Uri.parse(url)); Navigator.pop(ctx); }, child: const Text('Download')),
        ],
      ),
    );
  }
}