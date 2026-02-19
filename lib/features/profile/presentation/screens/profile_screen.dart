import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/notification/presentation/providers/notification_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.valueOrNull;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isAnonymous = firebaseUser?.isAnonymous ?? false;
    final pushEnabledAsync = ref.watch(pushEnabledProvider);
    final isBusy = useState(false);

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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nickname?.trim().isNotEmpty == true
                          ? user!.nickname!.trim()
                          : 'Slow Daylog',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email.trim().isNotEmpty == true
                          ? user!.email.trim()
                          : 'Guest',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (isAnonymous) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.push('/signup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Link Account'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SwitchListTile.adaptive(
                  title: const Text('Notifications'),
                  subtitle: Text(
                    pushEnabledAsync.when(
                      data: (enabled) => enabled ? 'Enabled' : 'Disabled',
                      loading: () => 'Loading...',
                      error: (_, __) => 'Could not load preference',
                    ),
                  ),
                  value: pushEnabledAsync.valueOrNull ?? true,
                  onChanged: pushEnabledAsync.isLoading
                      ? null
                      : (value) async {
                          await ref
                              .read(pushEnabledProvider.notifier)
                              .setPushEnabled(value);

                          final updated = ref.read(pushEnabledProvider);
                          if (updated.hasError && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not update push preference.',
                                ),
                              ),
                            );
                          }
                        },
                  activeThumbColor: AppTheme.primaryColor,
                  activeTrackColor:
                      AppTheme.primaryColor.withValues(alpha: 0.35),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: isBusy.value ? null : handleLogout,
                style: FilledButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
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
                    : const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
