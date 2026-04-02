import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/notes_provider.dart';

/// Account tab — profile, settings, AI config, and sign-out.
class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

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

  Widget _buildMobileLayout(BuildContext context, bool isDark, Color primaryColor, SettingsProvider settings, AuthProvider auth) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              // --- App Bar Row (Mobile only) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_pin, color: primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Profile',
                        style: AppTheme.headline3(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    child: Text(
                      (auth.user?.displayName ?? 'U')[0].toUpperCase(),
                      style: AppTheme.labelLarge(color: primaryColor),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // --- Profile Header ---
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        backgroundImage: auth.user?.photoUrl != null ? NetworkImage(auth.user!.photoUrl!) : null,
                        child: auth.user?.photoUrl == null
                            ? Text(
                                (auth.user?.displayName ?? 'U')[0].toUpperCase(),
                                style: AppTheme.headline2(color: primaryColor),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      auth.user?.displayName ?? 'Explorer',
                      style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.user?.email ?? '',
                      style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

              const SizedBox(height: 32),

              // --- Theme & Accent ---
              Row(
                children: [
                  Expanded(
                    child: _SettingTile(
                      icon: Icons.palette_outlined,
                      iconColor: primaryColor,
                      title: 'App Theme',
                      subtitle: settings.themeMode == ThemeMode.dark ? 'Dark' : settings.themeMode == ThemeMode.light ? 'Light' : 'System',
                      isDark: isDark,
                      onTap: () => _showThemePicker(context, settings),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SettingTile(
                      icon: Icons.color_lens_outlined,
                      iconColor: const Color(0xFFF97316),
                      title: 'Accent',
                      subtitle: SettingsProvider.accentColors[settings.accentColorIndex].name,
                      isDark: isDark,
                      onTap: () => _showAccentPicker(context, settings),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // --- AI Config ---
              _buildAiConfigSection(context, settings, isDark, primaryColor),

              const SizedBox(height: 32),

              // --- Logout ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('SIGN OUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark, Color primaryColor, SettingsProvider settings, AuthProvider auth) {
    return SingleChildScrollView(
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
                        _buildSidebarItem(context, 'Profile Details', true, isDark),
                        _buildSidebarItem(context, 'Security', false, isDark),
                        
                        const SizedBox(height: 32),
                        Text('SYSTEM', style: AppTheme.labelSmall(color: isDark ? AppTheme.darkTextSecondary : Theme.of(context).colorScheme.outline).copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 16),
                        _buildSidebarItem(context, 'Theme & UI', false, isDark),
                        _buildSidebarItem(context, 'AI Models', false, isDark),
                        
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _handleLogout(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(color: Theme.of(context).colorScheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 64),
                  
                  // Main
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: isDark ? AppTheme.darkSurface : Theme.of(context).colorScheme.secondaryContainer,
                              backgroundImage: auth.user?.photoUrl != null ? NetworkImage(auth.user!.photoUrl!) : null,
                              child: auth.user?.photoUrl == null
                                  ? Text((auth.user?.displayName ?? 'U')[0].toUpperCase(), style: AppTheme.headline2(color: primaryColor))
                                  : null,
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(auth.user?.displayName ?? 'Explorer', style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary)),
                                const SizedBox(height: 4),
                                Text(auth.user?.email ?? '', style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextSecondary : Theme.of(context).colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary,
                                    side: BorderSide(color: isDark ? AppTheme.darkSurface : Theme.of(context).colorScheme.outlineVariant),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  child: const Text('Change Avatar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 48),
                        
                        Text('Theme & Locale', style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _SettingTile(icon: Icons.palette_outlined, iconColor: primaryColor, title: 'App Theme', subtitle: settings.themeMode == ThemeMode.dark ? 'Dark' : 'Light', isDark: isDark, onTap: () => _showThemePicker(context, settings))),
                            const SizedBox(width: 24),
                            Expanded(child: _SettingTile(icon: Icons.color_lens_outlined, iconColor: const Color(0xFFF97316), title: 'Accent Color', subtitle: SettingsProvider.accentColors[settings.accentColorIndex].name, isDark: isDark, onTap: () => _showAccentPicker(context, settings))),
                          ],
                        ),

                        const SizedBox(height: 48),

                        Text('AI Engine Configuration', style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : Theme.of(context).colorScheme.tertiary)),
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

  Widget _buildSidebarItem(BuildContext context, String title, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppTheme.darkSurface : Theme.of(context).colorScheme.secondaryContainer) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppTheme.bodyMedium(color: isSelected ? Theme.of(context).colorScheme.tertiary : (isDark ? AppTheme.darkTextSecondary : Theme.of(context).colorScheme.onSurfaceVariant)).copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAiConfigSection(BuildContext context, SettingsProvider settings, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
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
          const Divider(height: 32, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Smart Context', style: AppTheme.bodyLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
              Switch.adaptive(
                value: true,
                onChanged: (v) {},
                activeColor: primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Theme Mode', style: AppTheme.headline3()),
            const SizedBox(height: 24),
            ListTile(title: const Text('System Default'), leading: const Icon(Icons.brightness_auto), onTap: () { settings.setThemeMode(ThemeMode.system); Navigator.pop(context); }),
            ListTile(title: const Text('Light Mode'), leading: const Icon(Icons.light_mode), onTap: () { settings.setThemeMode(ThemeMode.light); Navigator.pop(context); }),
            ListTile(title: const Text('Dark Mode'), leading: const Icon(Icons.dark_mode), onTap: () { settings.setThemeMode(ThemeMode.dark); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  void _showAccentPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Accent Color', style: AppTheme.headline3()),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: SettingsProvider.accentColors.length,
                itemBuilder: (context, index) {
                  final c = SettingsProvider.accentColors[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: c.color),
                    title: Text(c.name),
                    onTap: () { settings.setAccentColor(index); Navigator.pop(context); },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select AI Model', style: AppTheme.headline3()),
            const SizedBox(height: 12),
            Text(
              'Choose your preferred intelligence engine for note generation.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.flash_on, color: AppTheme.teal),
              title: const Text('AIdea Cloud'),
              subtitle: const Text('Optimized for speed and quality (Recommended)'),
              trailing: settings.aiModel == AiModel.aidea
                  ? const Icon(Icons.check_circle, color: AppTheme.teal)
                  : null,
              onTap: () {
                settings.setAiModel(AiModel.aidea);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.google, color: Color(0xFF4285F4)),
              title: const Text('Google Gemini Pro'),
              subtitle: const Text('Direct access to Gemini using your API key'),
              trailing: settings.aiModel == AiModel.gemini
                  ? const Icon(Icons.check_circle, color: Color(0xFF4285F4))
                  : null,
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

  void _handleLogout(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notes = Provider.of<NotesProvider>(context, listen: false);
    auth.signOut();
    notes.clearSearch();
  }
}

class _SettingTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.darkTextSecondary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.labelSmall(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                  Text(subtitle, style: AppTheme.titleMedium(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}
