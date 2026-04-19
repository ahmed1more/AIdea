import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBg.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.8),
                      border: Border(
                        bottom: BorderSide(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AiDea',
                              style: AppTheme.headline3(
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return GestureDetector(
                                  onTap: () => setState(() => _currentIndex = 2),
                                  child: _buildProfileAvatar(
                                    auth: auth,
                                    isDark: isDark,
                                    primaryColor: primaryColor,
                                    radius: 20,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
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
      bottomNavigationBar: isDesktop
          ? null
          : ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBg.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 40,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MobileNavItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home,
                            label: 'Home',
                            isActive: _currentIndex == 0,
                            activeColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _currentIndex = 0),
                          ),
                          _MobileNavItem(
                            icon: Icons.bookmark_outline,
                            activeIcon: Icons.bookmark,
                            label: 'Favorites',
                            isActive: _currentIndex == 1,
                            activeColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                          _MobileNavItem(
                            icon: Icons.person_outline,
                            activeIcon: Icons.person,
                            label: 'Account',
                            isActive: _currentIndex == 2,
                            activeColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _currentIndex = 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

class _DesktopNavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _DesktopNavItem({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.labelLarge(
                color: isActive ? activeColor : inactiveColor,
              ).copyWith(fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 24,
                color: activeColor,
              ).animate().scaleX(duration: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark
        ? AppTheme.darkTextSecondary
        : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: AppTheme.labelSmall(
                color: isActive ? activeColor : inactiveColor,
              ).copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
