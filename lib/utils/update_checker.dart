import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class UpdateChecker {
  static const _repoOwner = 'aandrsta';
  static const _repoName = 'monetoo';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static Future<void> check(BuildContext context) async {
    try {
      final dio = Dio();
      final response =
          await dio.get(_apiUrl).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = response.data as Map<String, dynamic>;
      final latestTag = (data['tag_name'] as String).replaceAll('v', '');
      final downloadUrl = (data['assets'] as List).firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      )?['browser_download_url'] as String?;

      if (downloadUrl == null) return;

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      if (_isNewer(latestTag, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
              context, latestTag, downloadUrl, data['body'] as String? ?? '');
        }
      }
    } catch (_) {}
  }

  static bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String version,
    String downloadUrl,
    String changelog,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.system_update_rounded,
                  color: AppTheme.accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Update tersedia — v$version',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            if (changelog.isNotEmpty) ...[
              Text(
                changelog.length > 200
                    ? '${changelog.substring(0, 200)}...'
                    : changelog,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Nanti',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      launchUrl(Uri.parse(downloadUrl),
                          mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Download & Install',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
