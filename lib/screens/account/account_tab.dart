import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/notes_provider.dart';
import '../auth/signup_screen.dart';

/// Account tab — profile, settings, AI config, and sign-out.
class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> with SingleTickerProviderStateMixin {
  String _selectedSidebarItem = 'Profile Details';
  final ScrollController _scrollController = ScrollController();
  final _profileKey = GlobalKey();
  final _securityKey = GlobalKey();
  final _themeKey = GlobalKey();
  final _aiKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        body: _buildDesktopLayout(context, isDark, primaryColor, settings, auth),
      );
    }
    return _buildMobileLayout(context, isDark, primaryColor, settings, auth);
  }

  // ─── MOBILE LAYOUT ────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, bool isDark, Color primaryColor, SettingsProvider settings, AuthProvider auth) {
    final notes = Provider.of<NotesProvider>(context);

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              // ─── Header ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_rounded, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Profile',
                        style: AppTheme.headline3(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // ─── Profile Card ────────────────────────
              _buildProfileCard(context, auth, isDark, primaryColor, notes),

              const SizedBox(height: 24),

              // ─── Stats Row ────────────────────────────
              _buildStatsRow(context, auth, isDark, primaryColor, notes),

              const SizedBox(height: 32),

              // ─── Section: Appearance ──────────────────
              _buildSectionHeader('Appearance', Icons.palette_outlined, primaryColor, isDark, 300),

              const SizedBox(height: 16),

              _SettingTile(
                icon: Icons.contrast,
                iconColor: primaryColor,
                title: 'App Theme',
                subtitle: settings.themeMode == ThemeMode.dark
                    ? 'Dark Mode'
                    : settings.themeMode == ThemeMode.light
                        ? 'Light Mode'
                        : 'System Default',
                isDark: isDark,
                onTap: () => _showThemePicker(context, settings),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ─── Section: AI Engine ────────────────────
              _buildSectionHeader('AI Engine', Icons.auto_awesome, const Color(0xFF8B5CF6), isDark, 400),

              const SizedBox(height: 16),

              _buildAiConfigSection(context, settings, isDark, primaryColor),

              const SizedBox(height: 24),

              // ─── Section: Security ─────────────────────
              _buildSectionHeader('Security', Icons.shield_outlined, AppTheme.teal, isDark, 500),

              const SizedBox(height: 16),

              _buildSecuritySection(context, auth, isDark, primaryColor),

              const SizedBox(height: 32),

              // ─── Logout ───────────────────────────────
              _buildLogoutButton(context, isDark, primaryColor),

              const SizedBox(height: 16),

              // ─── Delete Account ────────────────────────
              _buildDeleteAccountButton(context, auth, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DESKTOP LAYOUT ───────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, bool isDark, Color primaryColor, SettingsProvider settings, AuthProvider auth) {
    final notes = Provider.of<NotesProvider>(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 100, bottom: 80, left: 32, right: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREFERENCES',
                style: AppTheme.labelSmall(color: primaryColor).copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              Text(
                'Settings & Identity',
                style: AppTheme.headline1(color: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary).copyWith(fontSize: 48),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 48),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACCOUNT', style: AppTheme.labelSmall(color: isDark ? AppTheme.darkTextSecondary : Theme.of(context).colorScheme.outline).copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 16),
                        _buildSidebarItem(context, 'Profile Details', isDark),
                        _buildSidebarItem(context, 'Security', isDark),
                        
                        const SizedBox(height: 32),
                        Text('SYSTEM', style: AppTheme.labelSmall(color: isDark ? AppTheme.darkTextSecondary : Theme.of(context).colorScheme.outline).copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 16),
                        _buildSidebarItem(context, 'Theme & UI', isDark),
                        _buildSidebarItem(context, 'AI Models', isDark),
                        
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleLogout(context),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => _showDeleteAccountDialog(context, auth),
                            child: Text(
                              'Delete Account',
                              style: AppTheme.bodySmall(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 64),
                  
                  // Main content
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile header
                        _buildDesktopProfileHeader(context, auth, isDark, primaryColor, notes),
                        
                        const SizedBox(height: 48),

                        // Security section
                        Text('Security', key: _securityKey, style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary)),
                        const SizedBox(height: 24),
                        _buildSecuritySection(context, auth, isDark, primaryColor),

                        const SizedBox(height: 48),
                        
                        Text('Theme & Locale', key: _themeKey, style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _SettingTile(icon: Icons.contrast, iconColor: primaryColor, title: 'App Theme', subtitle: settings.themeMode == ThemeMode.dark ? 'Dark' : 'Light', isDark: isDark, onTap: () => _showThemePicker(context, settings))),
                          ],
                        ),

                        const SizedBox(height: 48),

                        Text('AI Engine Configuration', key: _aiKey, style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary)),
                        const SizedBox(height: 24),
                        _buildAiConfigSection(context, settings, isDark, primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── REUSABLE WIDGETS ─────────────────────────────────────────────

  Widget _buildProfileCard(BuildContext context, AuthProvider auth, bool isDark, Color primaryColor, NotesProvider notes) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.darkSurface, AppTheme.darkSurface.withValues(alpha: 0.7)]
              : [Colors.white, primaryColor.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : primaryColor).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : primaryColor).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with edit button
          _buildAvatarWidget(context, auth, isDark, primaryColor, radius: 52),
          const SizedBox(height: 20),
          // Name
          Text(
            auth.user?.displayName ?? 'Explorer',
            style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
          const SizedBox(height: 6),
          // Email
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              auth.user?.email ?? '',
              style: AppTheme.bodySmall(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          const SizedBox(height: 20),
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(context, auth),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.05);
  }

  Widget _buildDesktopProfileHeader(BuildContext context, AuthProvider auth, bool isDark, Color primaryColor, NotesProvider notes) {
    return Container(
      key: _profileKey,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.darkSurface, AppTheme.darkSurface.withValues(alpha: 0.7)]
              : [Colors.white, primaryColor.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : primaryColor).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          _buildAvatarWidget(context, auth, isDark, primaryColor, radius: 52),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.user?.displayName ?? 'Explorer', style: AppTheme.headline2(color: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary)),
                const SizedBox(height: 6),
                Text(auth.user?.email ?? '', style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextSecondary : Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, auth),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.article_outlined, '${notes.notes.length}', 'Notes', isDark, primaryColor),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      Icons.calendar_today_outlined,
                      auth.user != null ? DateFormat('MMM yyyy').format(auth.user!.createdAt) : '—',
                      'Joined',
                      isDark,
                      AppTheme.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTheme.labelLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary).copyWith(fontSize: 12)),
              Text(label, style: AppTheme.bodySmall(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AuthProvider auth, bool isDark, Color primaryColor, NotesProvider notes) {
    final favCount = notes.notes.where((n) => n.isFavorite).length;
    return Row(
      children: [
        Expanded(child: _buildStatCard('Notes', '${notes.notes.length}', Icons.article_outlined, primaryColor, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Favorites', '$favCount', Icons.bookmark_outlined, AppTheme.coral, isDark)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Member Since',
            auth.user != null ? DateFormat('MMM yy').format(auth.user!.createdAt) : '—',
            Icons.calendar_today_outlined,
            AppTheme.teal,
            isDark,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTheme.titleMedium(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary).copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.bodySmall(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDark, int delayMs) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTheme.titleLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.3), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delayMs), duration: 400.ms);
  }

  Widget _buildAvatarWidget(BuildContext context, AuthProvider auth, bool isDark, Color primaryColor, {double radius = 48}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withValues(alpha: 0.5)],
            ),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            backgroundImage: auth.user?.photoUrl != null
                ? CachedNetworkImageProvider(auth.user!.photoUrl!)
                : null,
            child: _isUploadingPhoto
                ? SizedBox(
                    width: radius,
                    height: radius,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                    ),
                  )
                : auth.user?.photoUrl == null
                    ? Text(
                        (auth.user?.displayName ?? 'U')[0].toUpperCase(),
                        style: AppTheme.headline1(color: primaryColor).copyWith(fontSize: radius * 0.7),
                      )
                    : null,
          ),
        ),
        // Camera overlay button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showPhotoOptions(context, auth),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppTheme.darkBg : Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: radius * 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context, AuthProvider auth, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.lock_outline,
            iconColor: AppTheme.teal,
            title: 'Change Password',
            subtitle: 'Update your account password',
            isDark: isDark,
            onTap: () => _showChangePasswordDialog(context, auth),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),
          _SettingTile(
            icon: Icons.email_outlined,
            iconColor: primaryColor,
            title: 'Email Address',
            subtitle: auth.user?.email ?? 'Not set',
            isDark: isDark,
            onTap: () => _showToast('Email cannot be changed for security reasons'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 550.ms, duration: 400.ms);
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('SIGN OUT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildDeleteAccountButton(BuildContext context, AuthProvider auth, bool isDark) {
    return Center(
      child: TextButton(
        onPressed: () => _showDeleteAccountDialog(context, auth),
        child: Text(
          'Delete Account',
          style: AppTheme.bodySmall(
            color: AppTheme.error.withValues(alpha: 0.6),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 650.ms);
  }

  Widget _buildSidebarItem(BuildContext context, String title, bool isDark) {
    final isSelected = _selectedSidebarItem == title;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () {
        setState(() => _selectedSidebarItem = title);
        _scrollToSection(title);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: primaryColor.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTheme.bodyMedium(
                color: isSelected
                    ? primaryColor
                    : (isDark ? AppTheme.darkTextSecondary : Theme.of(context).colorScheme.onSurfaceVariant),
              ).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiConfigSection(BuildContext context, SettingsProvider settings, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Preferred Model',
            subtitle: settings.aiModelLabel,
            isDark: isDark,
            onTap: () => _showModelPicker(context, settings),
          ),
          Divider(
            height: 32,
            thickness: 0.5,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.psychology_outlined, color: AppTheme.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Smart Context', style: AppTheme.bodyLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
                ],
              ),
              Switch.adaptive(
                value: settings.smartContext,
                onChanged: (v) => settings.setSmartContext(v),
                activeTrackColor: primaryColor,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms, duration: 400.ms);
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────

  void _showPhotoOptions(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Profile Photo', style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library_outlined, color: primaryColor),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: Text('Select an existing photo', style: AppTheme.bodySmall(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery, auth);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppTheme.teal),
              ),
              title: const Text('Take a Photo'),
              subtitle: Text('Use your camera', style: AppTheme.bodySmall(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera, auth);
              },
            ),
            if (auth.user?.photoUrl != null) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppTheme.error),
                ),
                title: const Text('Remove Photo'),
                subtitle: Text('Use default avatar', style: AppTheme.bodySmall(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _isUploadingPhoto = true);
                  final success = await auth.removeProfilePhoto();
                  setState(() => _isUploadingPhoto = false);
                  if (mounted) {
                    _showToast(
                      success ? 'Photo removed' : 'Failed to remove photo',
                      isError: !success,
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source, AuthProvider auth) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isUploadingPhoto = true);
      final success = await auth.updateProfilePhoto(File(image.path));
      setState(() => _isUploadingPhoto = false);

      if (mounted) {
        _showToast(
          success ? 'Profile photo updated!' : 'Failed to upload photo',
          isError: !success,
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        _showToast('Error: $e', isError: true);
      }
    }
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Theme Mode', style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
            const SizedBox(height: 24),
            _buildThemeOption(context, 'System Default', Icons.brightness_auto, settings.themeMode == ThemeMode.system, () { settings.setThemeMode(ThemeMode.system); Navigator.pop(context); }),
            _buildThemeOption(context, 'Light Mode', Icons.light_mode, settings.themeMode == ThemeMode.light, () { settings.setThemeMode(ThemeMode.light); Navigator.pop(context); }),
            _buildThemeOption(context, 'Dark Mode', Icons.dark_mode, settings.themeMode == ThemeMode.dark, () { settings.setThemeMode(ThemeMode.dark); Navigator.pop(context); }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon, bool isSelected, VoidCallback onTap) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isSelected ? primaryColor : (isDark ? Colors.white : Colors.black)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isSelected ? primaryColor : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
      ),
      title: Text(title),
      trailing: isSelected ? Icon(Icons.check_circle, color: primaryColor) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  void _showModelPicker(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Select AI Model', style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
            const SizedBox(height: 12),
            Text(
              'Choose your preferred intelligence engine for note generation.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on, color: AppTheme.teal),
              ),
              title: const Text('AIdea Cloud'),
              subtitle: const Text('Optimized for speed and quality (Recommended)'),
              trailing: settings.aiModel == AiModel.aidea
                  ? const Icon(Icons.check_circle, color: AppTheme.teal)
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                settings.setAiModel(AiModel.aidea);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF4285F4)),
              ),
              title: const Text('Google Gemini Pro'),
              subtitle: const Text('Direct access to Gemini using your API key'),
              trailing: settings.aiModel == AiModel.gemini
                  ? const Icon(Icons.check_circle, color: Color(0xFF4285F4))
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                settings.setAiModel(AiModel.gemini);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _scrollToSection(String title) {
    GlobalKey? targetKey;
    switch (title) {
      case 'Profile Details':
        targetKey = _profileKey;
        break;
      case 'Security':
        targetKey = _securityKey;
        break;
      case 'Theme & UI':
        targetKey = _themeKey;
        break;
      case 'AI Models':
        targetKey = _aiKey;
        break;
    }
    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final nameController = TextEditingController(text: auth.user?.displayName ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar at top
            _buildAvatarWidget(dialogContext, auth, isDark, primaryColor, radius: 44),
            const SizedBox(height: 24),
            Text('Edit Profile', style: AppTheme.headline3(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            )),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: AppTheme.bodyLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              decoration: InputDecoration(
                labelText: 'DISPLAY NAME',
                prefixIcon: Icon(Icons.person_outline, color: primaryColor, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  const SizedBox(width: 8),
                  Text(
                    auth.user?.email ?? 'N/A',
                    style: AppTheme.bodySmall(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != auth.user?.displayName) {
                final success = await auth.updateDisplayName(newName);
                if (context.mounted) {
                  _showToast(
                    success ? 'Profile updated!' : 'Failed to update',
                    isError: !success,
                  );
                }
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline, color: AppTheme.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Change Password', style: AppTheme.headline3(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ).copyWith(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final current = currentPasswordController.text;
                final newPass = newPasswordController.text;
                final confirm = confirmPasswordController.text;

                if (current.isEmpty || newPass.isEmpty) {
                  _showToast('Please fill in all fields', isError: true);
                  return;
                }
                if (newPass.length < 6) {
                  _showToast('Password must be at least 6 characters', isError: true);
                  return;
                }
                if (newPass != confirm) {
                  _showToast('Passwords do not match', isError: true);
                  return;
                }

                final success = await auth.changePassword(
                  currentPassword: current,
                  newPassword: newPass,
                );

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  _showToast(
                    success ? 'Password changed successfully!' : auth.errorMessage ?? 'Failed to change password',
                    isError: !success,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    final passwordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Delete Account', style: AppTheme.headline3(
              color: AppTheme.error,
            ).copyWith(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This action is permanent and cannot be undone. All your notes, data, and profile will be deleted.',
              style: AppTheme.bodyMedium(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter your password to confirm',
                prefixIcon: const Icon(Icons.lock, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.error, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) {
                _showToast('Please enter your password', isError: true);
                return;
              }

              final success = await auth.deleteAccount(password);
              if (dialogContext.mounted) Navigator.pop(dialogContext);

              if (success && context.mounted) {
                final notes = Provider.of<NotesProvider>(context, listen: false);
                notes.clear();
                notes.clearSearch();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  (route) => false,
                );
              } else if (context.mounted) {
                _showToast(auth.errorMessage ?? 'Failed to delete account', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign Out', style: AppTheme.headline3(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        )),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTheme.bodyMedium(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final notes = Provider.of<NotesProvider>(context, listen: false);
              auth.signOut();
              notes.clear();
              notes.clearSearch();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── SETTING TILE ─────────────────────────────────────────────────
class _SettingTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.iconColor.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTheme.titleMedium(color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary).copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: AppTheme.bodySmall(color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
