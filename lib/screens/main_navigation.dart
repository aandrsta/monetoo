// lib/screens/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../utils/app_theme.dart';
import 'transaction_screen.dart';
import 'category_screen.dart';
import 'statistics_screen.dart';
import 'account_screen.dart';

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
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          color: Colors.white,
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
              rippleColor: AppTheme.accent.withValues(alpha: 0.15),
              hoverColor: AppTheme.accent.withValues(alpha: 0.1),
              gap: 8,
              activeColor: AppTheme.accent,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppTheme.accent.withValues(alpha: 0.1),
              color: AppTheme.textSecondary,
              tabs: const [
                GButton(
                  icon: Icons.account_balance_wallet_rounded,
                  text: 'Akun',
                ),
                GButton(
                  icon: Icons.receipt_long_rounded,
                  text: 'Transaksi',
                ),
                GButton(
                  icon: Icons.category_rounded,
                  text: 'Kategori',
                ),
                GButton(
                  icon: Icons.bar_chart_rounded,
                  text: 'Statistik',
                ),
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
