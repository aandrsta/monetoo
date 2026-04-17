// lib/utils/update_checker.dart

import 'dart:io';
import 'package:Monetoo/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'app_toast.dart';

class UpdateChecker {
  static const _repoOwner = 'aandrsta';
  static const _repoName = 'monetoo';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static Future<void> check(BuildContext context) async {
    try {
      final dio = Dio();
      final response = await dio
          .get(
            _apiUrl,
            options:
                Options(headers: {'Accept': 'application/vnd.github+json'}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;

      final data = response.data as Map<String, dynamic>;
      final latestTag = (data['tag_name'] as String).replaceAll('v', '');
      final downloadUrl = (data['assets'] as List).firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      )?['browser_download_url'] as String?;

      if (downloadUrl == null) return;

      final info = await PackageInfo.fromPlatform();
      if (_isNewer(latestTag, info.version)) {
        if (context.mounted) {
          _showUpdateDialog(
              context, latestTag, downloadUrl, data['body'] as String? ?? '');
        }
      }
    } catch (_) {}
  }

  static Future<void> checkManual(BuildContext context) async {
    try {
      final dio = Dio();
      final response = await dio
          .get(
            _apiUrl,
            options:
                Options(headers: {'Accept': 'application/vnd.github+json'}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (context.mounted) {
          AppToast.error(context, 'Gagal menghubungi server');
        }
        return;
      }

      final data = response.data as Map<String, dynamic>;
      final latestTag = (data['tag_name'] as String).replaceAll('v', '');
      final downloadUrl = (data['assets'] as List).firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      )?['browser_download_url'] as String?;

      final info = await PackageInfo.fromPlatform();

      if (!context.mounted) return;

      if (downloadUrl != null && _isNewer(latestTag, info.version)) {
        _showUpdateDialog(
            context, latestTag, downloadUrl, data['body'] as String? ?? '');
      } else {
        AppToast.success(
            context, 'Aplikasi sudah versi terbaru (v${info.version})');
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'Tidak dapat memeriksa pembaruan');
      }
    }
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
      builder: (ctx) => _UpdateSheet(
        version: version,
        downloadUrl: downloadUrl,
        changelog: changelog,
      ),
    );
  }
}

class _UpdateSheet extends StatefulWidget {
  final String version;
  final String downloadUrl;
  final String changelog;

  const _UpdateSheet({
    required this.version,
    required this.downloadUrl,
    required this.changelog,
  });

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  double _progress = 0;
  bool _isDownloading = false;
  String _statusText = '';
  final CancelToken _cancelToken = CancelToken();

  @override
  void dispose() {
    if (_isDownloading) _cancelToken.cancel();
    super.dispose();
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Mempersiapkan...';
      _progress = 0;
    });

    try {
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          _showError('Izin instalasi diperlukan. Aktifkan di Pengaturan.');
          return;
        }
      }

      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/monetoo_update.apk';

      final file = File(savePath);
      if (await file.exists()) await file.delete();

      setState(() => _statusText = 'Mengunduh...');

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _progress = received / total;
              final mb = (received / 1024 / 1024).toStringAsFixed(1);
              final totalMb = (total / 1024 / 1024).toStringAsFixed(1);
              _statusText = '$mb MB / $totalMb MB';
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _statusText = 'Membuka installer...');

      final result = await OpenFile.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done && mounted) {
        _showError('Gagal membuka installer: ${result.message}');
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (mounted) _showError('Gagal mengunduh update');
    }
  }

  void _showError(String msg) {
    final c = context.colors;
    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _statusText = '';
      _progress = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: c.expense,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: c.divider, borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.system_update_rounded, color: c.accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Update tersedia — v${widget.version}',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary),
          ),
          const SizedBox(height: 8),
          if (widget.changelog.isNotEmpty)
            Text(
              widget.changelog.length > 200
                  ? '${widget.changelog.substring(0, 200)}...'
                  : widget.changelog,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
            ),
          const SizedBox(height: 20),
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor: c.bgLight,
                valueColor: AlwaysStoppedAnimation<Color>(c.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              if (!_isDownloading) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: c.bgLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          'Nanti',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _isDownloading ? null : _downloadAndInstall,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isDownloading
                          ? c.accent.withValues(alpha: 0.5)
                          : c.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isDownloading
                          ? Text(
                              'Mengunduh...',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: c.cardBg),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Download & Install',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
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
    );
  }
}
