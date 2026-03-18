// lib/utils/update_checker.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
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
      if (_isNewer(latestTag, info.version)) {
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
      builder: (ctx) => _UpdateSheet(
        version: version,
        downloadUrl: downloadUrl,
        changelog: changelog,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UPDATE SHEET
// ─────────────────────────────────────────────

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
      // 1. Minta izin install dari sumber tidak dikenal (Android 8+)
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          _showError('Izin instalasi diperlukan. Aktifkan di Pengaturan.');
          return;
        }
      }

      // 2. Tentukan path penyimpanan APK
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/monetoo_update.apk';

      // Hapus file lama jika ada
      final file = File(savePath);
      if (await file.exists()) await file.delete();

      setState(() => _statusText = 'Mengunduh...');

      // 3. Download APK dengan progress
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

      // 4. Buka installer Android native lewat open_file
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
    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _statusText = '';
      _progress = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.expense,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Ikon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.system_update_rounded,
                color: AppTheme.accent, size: 28),
          ),
          const SizedBox(height: 16),

          // Judul
          Text(
            'Update tersedia — v${widget.version}',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),

          // Changelog
          if (widget.changelog.isNotEmpty)
            Text(
              widget.changelog.length > 200
                  ? '${widget.changelog.substring(0, 200)}...'
                  : widget.changelog,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
          const SizedBox(height: 20),

          // Progress bar — hanya muncul saat download
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor: AppTheme.bgLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
          ],

          // Tombol
          Row(
            children: [
              // Tombol "Nanti" — hilang saat sedang download
              if (!_isDownloading) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text(
                          'Nanti',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Tombol download / status
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _isDownloading ? null : _downloadAndInstall,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _isDownloading
                          ? AppTheme.accent.withValues(alpha: 0.5)
                          : AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isDownloading
                          ? const Text(
                              'Mengunduh...',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
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
