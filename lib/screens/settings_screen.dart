// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import '../utils/update_checker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    await UpdateChecker.checkManual(context);
    if (mounted) setState(() => _checkingUpdate = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Pengaturan',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Tampilan'),
                    _card(children: [
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return _themeTile(
                            isDarkMode: themeProvider.isDarkMode,
                            onToggle: (value) {
                              themeProvider.setDarkMode(value);
                            },
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _sectionLabel('Tentang Aplikasi'),
                    _card(children: [
                      _infoTile(
                          icon: Icons.apps_rounded,
                          label: 'Aplikasi',
                          value: 'Monetoo'),
                      _dividerThin(),
                      _infoTile(
                          icon: Icons.tag_rounded,
                          label: 'Versi',
                          value: _version.isEmpty ? '...' : 'v$_version'),
                    ]),
                    const SizedBox(height: 20),
                    _sectionLabel('Pembaruan'),
                    _card(children: [
                      _actionTile(
                        icon: Icons.system_update_rounded,
                        iconColor: c.accent,
                        label: 'Periksa Pembaruan',
                        subtitle: 'Cek versi terbaru dari GitHub',
                        trailing: _checkingUpdate
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: c.accent),
                              )
                            : Icon(Icons.chevron_right_rounded,
                                color: c.textSecondary, size: 20),
                        onTap: _checkingUpdate ? null : _checkUpdate,
                      ),
                    ]),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        _version.isEmpty ? '' : 'Monetoo v$_version',
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: c.textSecondary,
            letterSpacing: 0.8),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: c.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _dividerThin() {
    final c = context.colors;
    return Divider(height: 1, indent: 52, endIndent: 0, color: c.divider);
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.bgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: c.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 14, color: c.textPrimary)),
          ),
          Text(value, style: TextStyle(fontSize: 14, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: c.textSecondary)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _themeTile({
    required bool isDarkMode,
    required Function(bool) onToggle,
  }) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: c.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode Gelap',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDarkMode ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isDarkMode,
            onChanged: onToggle,
            activeThumbColor: c.cardBg,
            activeTrackColor: c.accent,
          ),
        ],
      ),
    );
  }
}
