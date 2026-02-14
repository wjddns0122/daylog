import 'package:daylog/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final pushNotificationEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPushEnabled = ref.watch(pushNotificationEnabledProvider);
    final isBusy = useState(false);
    final currentUser = FirebaseAuth.instance.currentUser;

    Future<void> handleLogout() async {
      if (isBusy.value) {
        return;
      }

      isBusy.value = true;
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그아웃에 실패했어요. 다시 시도해주세요.')),
          );
        }
      } finally {
        isBusy.value = false;
      }
    }

    void showDummyNotice(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title is coming soon.')),
      );
    }

    final titleStyle = GoogleFonts.lora(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppTheme.primaryColor,
    );

    final itemTitleStyle = GoogleFonts.lora(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppTheme.primaryColor,
    );

    final itemSubtitleStyle = GoogleFonts.lora(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppTheme.textSecondary,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryColor,
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.lora(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _SettingsSection(
              title: 'Account',
              titleStyle: titleStyle,
              children: [
                _SettingsItem(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  subtitle: currentUser?.email ?? 'Guest',
                  titleStyle: itemTitleStyle,
                  subtitleStyle: itemSubtitleStyle,
                ),
                _SettingsItem(
                  icon: Icons.password_rounded,
                  title: 'Change Password',
                  subtitle: 'Not available yet',
                  titleStyle: itemTitleStyle,
                  subtitleStyle: itemSubtitleStyle,
                  onTap: () => showDummyNotice('Change Password'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Notifications',
              titleStyle: titleStyle,
              children: [
                SwitchListTile.adaptive(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text('Push Notifications', style: itemTitleStyle),
                  subtitle: Text(
                    isPushEnabled ? 'Enabled' : 'Disabled',
                    style: itemSubtitleStyle,
                  ),
                  value: isPushEnabled,
                  activeThumbColor: AppTheme.primaryColor,
                  activeTrackColor:
                      AppTheme.primaryColor.withValues(alpha: 0.3),
                  onChanged: (value) {
                    ref.read(pushNotificationEnabledProvider.notifier).state =
                        value;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'About',
              titleStyle: titleStyle,
              children: [
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                  titleStyle: itemTitleStyle,
                  subtitleStyle: itemSubtitleStyle,
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms',
                  subtitle: 'Read terms and conditions',
                  titleStyle: itemTitleStyle,
                  subtitleStyle: itemSubtitleStyle,
                  onTap: () => showDummyNotice('Terms'),
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy',
                  subtitle: 'Read privacy policy',
                  titleStyle: itemTitleStyle,
                  subtitleStyle: itemSubtitleStyle,
                  onTap: () => showDummyNotice('Privacy'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: isBusy.value ? null : handleLogout,
              style: FilledButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                backgroundColor: Colors.white.withValues(alpha: 0.75),
                side: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isBusy.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Logout',
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.titleStyle,
    required this.children,
  });

  final String title;
  final TextStyle titleStyle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(title, style: titleStyle),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleStyle,
    required this.subtitleStyle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: titleStyle),
      subtitle: Text(subtitle, style: subtitleStyle),
      trailing: onTap == null
          ? null
          : Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primaryColor.withValues(alpha: 0.8),
            ),
      onTap: onTap,
    );
  }
}
