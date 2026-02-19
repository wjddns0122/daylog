import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChangePasswordScreen extends HookConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final currentPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isSaving = useState(false);
    final obscureCurrentPassword = useState(true);
    final obscureNewPassword = useState(true);
    final obscureConfirmPassword = useState(true);

    String? currentPasswordValidator(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter your current password.';
      }
      return null;
    }

    String? newPasswordValidator(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a new password.';
      }
      if (value.length < 8) {
        return 'Password must be at least 8 characters.';
      }
      if (value == currentPasswordController.text) {
        return 'New password must be different from current password.';
      }
      return null;
    }

    String? confirmPasswordValidator(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your new password.';
      }
      if (value != newPasswordController.text) {
        return 'Passwords do not match.';
      }
      return null;
    }

    String mapPasswordError(FirebaseAuthException error) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Current password is incorrect.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'requires-recent-login':
          return 'For security reasons, please log out and log in again before changing your password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ??
              'Failed to change password. Please try again.';
      }
    }

    Future<void> handleSave() async {
      if (isSaving.value) {
        return;
      }
      FocusScope.of(context).unfocus();

      final isValid = formKey.currentState?.validate() ?? false;
      if (!isValid) {
        return;
      }

      isSaving.value = true;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();

      try {
        await ref.read(authViewModelProvider.notifier).updatePassword(
              currentPassword: currentPasswordController.text,
              newPassword: newPasswordController.text,
            );

        if (!context.mounted) {
          return;
        }

        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        messenger.showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
      } on FirebaseAuthException catch (error) {
        if (!context.mounted) {
          return;
        }
        messenger.showSnackBar(
          SnackBar(content: Text(mapPasswordError(error))),
        );
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to change password. Please try again.'),
          ),
        );
      } finally {
        if (context.mounted) {
          isSaving.value = false;
        }
      }
    }

    final labelStyle = GoogleFonts.lora(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppTheme.primaryColor,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Change Password',
          style: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update your account password',
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use at least 8 characters and keep it private.',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword.value,
                      textInputAction: TextInputAction.next,
                      validator: currentPasswordValidator,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: labelStyle,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            obscureCurrentPassword.value =
                                !obscureCurrentPassword.value;
                          },
                          icon: Icon(
                            obscureCurrentPassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword.value,
                      textInputAction: TextInputAction.next,
                      validator: newPasswordValidator,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: labelStyle,
                        prefixIcon: const Icon(Icons.password_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            obscureNewPassword.value =
                                !obscureNewPassword.value;
                          },
                          icon: Icon(
                            obscureNewPassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword.value,
                      textInputAction: TextInputAction.done,
                      validator: confirmPasswordValidator,
                      onFieldSubmitted: (_) => handleSave(),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: labelStyle,
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            obscureConfirmPassword.value =
                                !obscureConfirmPassword.value;
                          },
                          icon: Icon(
                            obscureConfirmPassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSaving.value ? null : handleSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSaving.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save',
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
