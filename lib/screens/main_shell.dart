import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'favorites/favorites_tab.dart';
import 'account/account_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeScreen(),
    FavoritesTab(),
    AccountTab(),
  ];

  /// Public method so child widgets can switch tabs
  void switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      extendBody: true,
      appBar: null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: IndexedStack(
          key: ValueKey(_currentIndex),
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  /// Reusable profile avatar that shows photo or initials
  static Widget _buildProfileAvatar({
    required AuthProvider auth,
    required bool isDark,
    required Color primaryColor,
    double radius = 20,
  }) {
    final name = auth.user?.displayName ?? 'U';
    final photoUrl = auth.user?.photoUrl;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl)
            : null,
        child: photoUrl == null
            ? Text(
                name[0].toUpperCase(),
                style: AppTheme.labelLarge(color: primaryColor).copyWith(
                  fontSize: radius * 0.8,
                ),
              )
            : null,
      ),
    );
  }
}


// Removed redundant navigation items as main_shell no longer manages its own bottom bar.

