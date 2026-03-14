import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/settings_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background Color
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                // ── Account Section ──
                _buildSectionHeader(
                  context,
                  'Account',
                  FontAwesomeIcons.userLarge,
                ),
                _buildAccountCard(context, settings, isDark),
                const SizedBox(height: 16),



                // ── Appearance Section ──
                _buildSectionHeader(
                  context,
                  'Appearance',
                  FontAwesomeIcons.palette,
                ),
                _buildThemeModeCard(context, settings, isDark),
                const SizedBox(height: 16),

                // ── Themes Section ──
                _buildSectionHeader(
                  context,
                  'Color Palette',
                  FontAwesomeIcons.droplet,
                ),
                _buildAccentColorCard(context, settings, isDark),
                const SizedBox(height: 16),

                // ── About Section ──
                _buildSectionHeader(
                  context,
                  'About AIdea',
                  FontAwesomeIcons.circleInfo,
                ),
                _buildAboutCard(context, settings, isDark),
                const SizedBox(height: 40),

                // ── Logout Button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                      color: Colors.red.withOpacity(0.05),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const FaIcon(
                        FontAwesomeIcons.rightFromBracket,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: Text(
                        'LOGOUT',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          FaIcon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Account Card ──
  Widget _buildAccountCard(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: settings.glassMorphicContainer(
        context: context,
        padding: const EdgeInsets.all(20),
        opacity: isDark ? 0.05 : 0.7,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: settings.accentColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: settings.accentColor.withOpacity(0.2),
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? Text(
                        (user?.displayName ?? 'U')[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: settings.accentColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Welcome Explorer',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    user?.email ?? 'Connect your account',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: settings.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.solidNoteSticky,
                          size: 10,
                          color: settings.accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${user?.notesCount ?? 0} Brilliant Notes',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: settings.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1);
  }

  // ── Theme Mode Card ──
  Widget _buildThemeModeCard(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: settings.glassMorphicContainer(
        context: context,
        padding: const EdgeInsets.all(20),
        opacity: isDark ? 0.05 : 0.7,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildThemeToggleItem(
                  context,
                  ThemeMode.light,
                  FontAwesomeIcons.sun,
                  'Light',
                  settings,
                ),
                _buildThemeToggleItem(
                  context,
                  ThemeMode.dark,
                  FontAwesomeIcons.moon,
                  'Dark',
                  settings,
                ),
                _buildThemeToggleItem(
                  context,
                  ThemeMode.system,
                  FontAwesomeIcons.circleHalfStroke,
                  'Auto',
                  settings,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildThemeToggleItem(
    BuildContext context,
    ThemeMode mode,
    IconData icon,
    String label,
    SettingsProvider settings,
  ) {
    final isSelected = settings.themeMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => settings.setThemeMode(mode),
      child: AnimatedContainer(
        duration: 300.ms,
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? settings.accentColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? settings.accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            FaIcon(
              icon,
              size: 20,
              color: isSelected
                  ? settings.accentColor
                  : (isDark ? Colors.white38 : Colors.black26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? settings.accentColor
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Accent Color Card ──
  Widget _buildAccentColorCard(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: settings.glassMorphicContainer(
        context: context,
        padding: const EdgeInsets.all(20),
        opacity: isDark ? 0.05 : 0.7,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accent Color',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(SettingsProvider.accentColors.length, (
                index,
              ) {
                final accentColor = SettingsProvider.accentColors[index];
                final isSelected = settings.accentColorIndex == index;
                return GestureDetector(
                  onTap: () => settings.setAccentColor(index),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: 300.ms,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accentColor.color,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: accentColor.color.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      if (isSelected)
                        const FaIcon(
                          FontAwesomeIcons.check,
                          color: Colors.white,
                          size: 14,
                        ).animate().scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              SettingsProvider.accentColors[settings.accentColorIndex].name +
                  ' Theme',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: settings.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1);
  }

  // ── About Card ──
  Widget _buildAboutCard(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: settings.glassMorphicContainer(
        context: context,
        padding: const EdgeInsets.all(24),
        opacity: isDark ? 0.05 : 0.7,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 60, height: 60, child: settings.logo(size: 60))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 2.seconds, color: Colors.white24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AIdea App',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'The Future of Video Intelligence',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: settings.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'AIdea simplifies learning by generating beautiful, AI-powered notes directly from your favorite videos. Your notes are stored securely and accessible anywhere.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.solidHeart,
                  size: 12,
                  color: settings.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Handcrafted with Love',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1);
  }


  Widget _buildDropdown({
    required dynamic value,
    required Map<dynamic, String> items,
    required Function(dynamic) onChanged,
    required bool isDark,
    required SettingsProvider settings,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: GoogleFonts.inter(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String initialValue,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    required bool isDark,
    required SettingsProvider settings,
    bool obscure = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        initialValue: initialValue,
        obscureText: obscure,
        style: GoogleFonts.inter(fontSize: 14),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FaIcon(icon, size: 14, color: settings.accentColor),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ── Logout Handler ──
  Future<void> _handleLogout(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final confirmed = await settings.showGlassDialog<bool>(
      context: context,
      title: 'Logout Confirmation',
      content: Text(
        'Are you sure you want to end your current session?',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Keep Signed In',
            style: GoogleFonts.poppins(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.black45,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            color: Colors.redAccent.withOpacity(0.1),
          ),
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const FaIcon(
              FontAwesomeIcons.rightFromBracket,
              size: 14,
              color: Colors.redAccent,
            ),
            label: Text(
              'LOGOUT',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
      ],
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);

      await authProvider.signOut();
      notesProvider.clearSearch();
      // notesProvider.clear(); // If there was a clear method, use it or clear notes specifically if needed.

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
