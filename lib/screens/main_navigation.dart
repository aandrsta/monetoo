// lib/screens/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../utils/app_colors.dart';
import '../utils/update_checker.dart';
import 'transaction_screen.dart';
import 'category_screen.dart';
import 'statistics_screen.dart';
import 'account_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = const [
    AccountScreen(),
    TransactionScreen(),
    CategoryScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UpdateChecker.check(context);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.navBarBg,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: c.accent.withValues(alpha: 0.15),
              hoverColor: c.accent.withValues(alpha: 0.1),
              gap: 8,
              activeColor: c.accent,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: c.accent.withValues(alpha: 0.1),
              color: c.textSecondary,
              tabs: const [
                GButton(
                    icon: Icons.account_balance_wallet_rounded, text: 'Akun'),
                GButton(icon: Icons.receipt_long_rounded, text: 'Transaksi'),
                GButton(icon: Icons.category_rounded, text: 'Kategori'),
                GButton(icon: Icons.bar_chart_rounded, text: 'Statistik'),
                GButton(icon: Icons.settings_rounded, text: 'Pengaturan'),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                setState(() => _currentIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
