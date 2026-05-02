import 'dart:io';
import 'package:flutter/foundation.dart';
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
import '../auth/login_screen.dart';

/// Account tab ΓÇö profile, settings, AI config, and sign-out.
class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab>
    with SingleTickerProviderStateMixin {
  String _selectedSidebarItem = 'Profile Details';
  final ScrollController _scrollController = ScrollController();
  final _profileKey = GlobalKey();
  final _securityKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

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
      return _buildDesktopLayout(
        context,
        isDark,
        primaryColor,
        settings,
        auth,
      );
    }
    return _buildMobileLayout(context, isDark, primaryColor, settings, auth);
  }

  // ΓöÇΓöÇΓöÇ MOBILE LAYOUT ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildMobileLayout(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    SettingsProvider settings,
    AuthProvider auth,
  ) {
    final notes = Provider.of<NotesProvider>(context);

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              // ΓöÇΓöÇΓöÇ Header ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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
                        child: Icon(
                          Icons.person_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Profile',
                        style:
                            AppTheme.headline3(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ).copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // ΓöÇΓöÇΓöÇ Profile Card ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              _buildProfileCard(context, auth, isDark, primaryColor, notes),

              const SizedBox(height: 24),

              // ΓöÇΓöÇΓöÇ Stats Row ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              _buildStatsRow(context, auth, isDark, primaryColor, notes),

              const SizedBox(height: 32),


              // ΓöÇΓöÇΓöÇ Section: Security ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              _buildSectionHeader(
                'Security',
                Icons.shield_outlined,
                AppTheme.teal,
                isDark,
                500,
              ),

              const SizedBox(height: 16),

              _buildSecuritySection(context, auth, isDark, primaryColor),

              const SizedBox(height: 32),

              // ΓöÇΓöÇΓöÇ Logout ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              _buildLogoutButton(context, isDark, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // ΓöÇΓöÇΓöÇ DESKTOP LAYOUT ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    SettingsProvider settings,
    AuthProvider auth,
  ) {
    final notes = Provider.of<NotesProvider>(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 40, bottom: 80, left: 32, right: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREFERENCES',
                style: AppTheme.labelSmall(
                  color: primaryColor,
                ).copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              Text(
                'Settings & Identity',
                style: AppTheme.headline1(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : Theme.of(context).colorScheme.tertiary,
                ).copyWith(fontSize: 48),
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
                        Text(
                          'ACCOUNT',
                          style:
                              AppTheme.labelSmall(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : Theme.of(context).colorScheme.outline,
                              ).copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildSidebarItem(context, 'Profile Details', isDark),
                        _buildSidebarItem(context, 'Security', isDark),

                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleLogout(context),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text(
                              'SIGN OUT',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                        _buildDesktopProfileHeader(
                          context,
                          auth,
                          isDark,
                          primaryColor,
                          notes,
                        ),

                        const SizedBox(height: 48),

                        // Security section
                        Text(
                          'Security',
                          key: _securityKey,
                          style: AppTheme.headline3(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSecuritySection(
                          context,
                          auth,
                          isDark,
                          primaryColor,
                        ),                      ],
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

  // ΓöÇΓöÇΓöÇ REUSABLE WIDGETS ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Widget _buildProfileCard(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    Color primaryColor,
    NotesProvider notes,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.darkSurface,
                  AppTheme.darkSurface.withValues(alpha: 0.7),
                ]
              : [Colors.white, primaryColor.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : primaryColor).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : primaryColor).withValues(
              alpha: 0.06,
            ),
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
            style: AppTheme.headline3(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          // Email
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.05,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              auth.user?.email ?? '',
              style: AppTheme.bodySmall(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.05);
  }

  Widget _buildDesktopProfileHeader(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    Color primaryColor,
    NotesProvider notes,
  ) {
    return Container(
      key: _profileKey,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.darkSurface,
                  AppTheme.darkSurface.withValues(alpha: 0.7),
                ]
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
                Text(
                  auth.user?.displayName ?? 'Explorer',
                  style: AppTheme.headline2(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.user?.email ?? '',
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, auth),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      Icons.article_outlined,
                      '${notes.notes.length}',
                      'Notes',
                      isDark,
                      primaryColor,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      Icons.calendar_today_outlined,
                      auth.user != null
                          ? DateFormat('MMM yyyy').format(auth.user!.createdAt)
                          : 'ΓÇö',
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

  Widget _buildMiniStat(
    IconData icon,
    String value,
    String label,
    bool isDark,
    Color color,
  ) {
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
              Text(
                value,
                style: AppTheme.labelLarge(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ).copyWith(fontSize: 12),
              ),
              Text(
                label,
                style: AppTheme.bodySmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ).copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    Color primaryColor,
    NotesProvider notes,
  ) {
    final favCount = notes.notes.where((n) => n.isFavorite).length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Notes',
            '${notes.notes.length}',
            Icons.article_outlined,
            primaryColor,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Favorites',
            '$favCount',
            Icons.bookmark_outlined,
            AppTheme.coral,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Member Since',
            auth.user != null
                ? DateFormat('MMM yy').format(auth.user!.createdAt)
                : 'ΓÇö',
            Icons.calendar_today_outlined,
            AppTheme.teal,
            isDark,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
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
          Text(
            value,
            style: AppTheme.titleMedium(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.bodySmall(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    bool isDark,
    int delayMs,
  ) {
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
          style: AppTheme.titleLarge(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
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
    ).animate().fadeIn(
      delay: Duration(milliseconds: delayMs),
      duration: 400.ms,
    );
  }

  Widget _buildAvatarWidget(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    Color primaryColor, {
    double radius = 48,
  }) {
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
            backgroundColor: isDark
                ? AppTheme.darkSurface
                : AppTheme.lightSurface,
            backgroundImage: auth.user?.photoUrl != null
                ? CachedNetworkImageProvider(auth.user!.photoUrl!)
                : null,
            child: auth.isUploadingPhoto
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
                    style: AppTheme.headline1(
                      color: primaryColor,
                    ).copyWith(fontSize: radius * 0.7),
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

  Widget _buildSecuritySection(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
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
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
          ),
          _SettingTile(
            icon: Icons.email_outlined,
            iconColor: primaryColor,
            title: 'Email Address',
            subtitle: auth.user?.email ?? 'Not set',
            isDark: isDark,
            onTap: () =>
                _showToast('Email cannot be changed for security reasons'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 550.ms, duration: 400.ms);
  }

  Widget _buildLogoutButton(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('SIGN OUT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? AppTheme.darkTextPrimary
              : AppTheme.lightTextPrimary,
          foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    ).animate().fadeIn();
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
              style:
                  AppTheme.bodyMedium(
                    color: isSelected
                        ? primaryColor
                        : (isDark
                              ? AppTheme.darkTextSecondary
                              : Theme.of(context).colorScheme.onSurfaceVariant),
                  ).copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ΓöÇΓöÇΓöÇ DIALOGS ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

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
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Profile Photo',
              style: AppTheme.headline3(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
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
              subtitle: Text(
                'Select an existing photo',
                style: AppTheme.bodySmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
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
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppTheme.teal,
                ),
              ),
              title: const Text('Take a Photo'),
              subtitle: Text(
                'Use your camera',
                style: AppTheme.bodySmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
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
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                  ),
                ),
                title: const Text('Remove Photo'),
                subtitle: Text(
                  'Use default avatar',
                  style: AppTheme.bodySmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await auth.removeProfilePhoto();
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

  Future<void> _pickAndUploadPhoto(
    ImageSource source,
    AuthProvider auth,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null) return;

      bool success;
      if (kIsWeb) {
        // Web: dart:io File is unavailable — use bytes instead
        final bytes = await image.readAsBytes();
        success = await auth.updateProfilePhotoBytes(bytes);
      } else {
        // Mobile / desktop
        success = await auth.updateProfilePhoto(File(image.path));
      }

      if (mounted) {
        _showToast(
          success ? 'Profile photo updated!' : 'Failed to upload photo',
          isError: !success,
        );
      }
    } catch (e) {
      if (mounted) _showToast('Error: $e', isError: true);
    }
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
    final nameController = TextEditingController(
      text: auth.user?.displayName ?? '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Pre-fill existing values
    String? selectedGender = auth.user?.gender;
    DateTime? selectedBirthDate;
    if (auth.user?.birthDate != null && auth.user!.birthDate!.isNotEmpty) {
      try {
        selectedBirthDate = DateTime.parse(auth.user!.birthDate!);
      } catch (_) {}
    }

    const genders = ['Male', 'Female'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(28),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar at top
                Center(
                  child: _buildAvatarWidget(
                    dialogContext,
                    auth,
                    isDark,
                    primaryColor,
                    radius: 44,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Edit Profile',
                    style: AppTheme.headline3(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Display Name ──────────────────────────
                TextField(
                  controller: nameController,
                  style: AppTheme.bodyLarge(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'DISPLAY NAME',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                        color:
                            (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Gender ────────────────────────────────
                Text(
                  'GENDER',
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ).copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genders.map((g) {
                    final isSelected = selectedGender == g;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedGender = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.1)),
                          ),
                        ),
                        child: Text(
                          g,
                          style: AppTheme.bodySmall(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary),
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Birth Date ────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate:
                          selectedBirthDate ?? DateTime(now.year - 20),
                      firstDate: DateTime(1920),
                      lastDate: DateTime(now.year - 5),
                      helpText: 'SELECT BIRTH DATE',
                    );
                    if (picked != null) {
                      setDialogState(() => selectedBirthDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'DATE OF BIRTH',
                      prefixIcon: Icon(
                        Icons.cake_outlined,
                        color: primaryColor,
                        size: 20,
                      ),
                      suffixIcon: Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Text(
                      selectedBirthDate != null
                          ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
                          : 'Select birth date',
                      style: AppTheme.bodyLarge(
                        color: selectedBirthDate != null
                            ? (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary)
                            : (isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Email (read-only) ─────────────────────
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'EMAIL ADDRESS',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    fillColor: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.03),
                    filled: true,
                  ),
                  child: Text(
                    auth.user?.email ?? 'N/A',
                    style: AppTheme.bodyLarge(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty &&
                    newName != auth.user?.displayName) {
                  await auth.updateDisplayName(newName);
                }
                // Save gender / birthDate via the completion method
                final birthDateStr = selectedBirthDate != null
                    ? '${selectedBirthDate!.year.toString().padLeft(4, '0')}-'
                        '${selectedBirthDate!.month.toString().padLeft(2, '0')}-'
                        '${selectedBirthDate!.day.toString().padLeft(2, '0')}'
                    : null;
                await auth.updateProfileCompletion(
                  gender: selectedGender,
                  birthDate: birthDateStr,
                );
                if (context.mounted) {
                  _showToast('Profile updated!');
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppTheme.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Change Password',
                style: AppTheme.headline3(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ).copyWith(fontSize: 18),
              ),
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
                    icon: Icon(
                      obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.1,
                      ),
                    ),
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
                    icon: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.1,
                      ),
                    ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.1,
                      ),
                    ),
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
                  _showToast(
                    'Password must be at least 6 characters',
                    isError: true,
                  );
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
                    success
                        ? 'Password changed successfully!'
                        : auth.errorMessage ?? 'Failed to change password',
                    isError: !success,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: const Text('Update Password'),
            ),
          ],
        ),
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
        title: Text(
          'Sign Out',
          style: AppTheme.headline3(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTheme.bodyMedium(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
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
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ΓöÇΓöÇΓöÇ SETTING TILE ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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
                    Text(
                      widget.title,
                      style: AppTheme.titleMedium(
                        color: widget.isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTheme.bodySmall(
                        color: widget.isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: (widget.isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
