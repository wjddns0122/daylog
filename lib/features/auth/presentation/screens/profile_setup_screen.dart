import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_button.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_header.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:daylog/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  int _step = 0;
  bool _isSubmitting = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).valueOrNull;
    if (user?.nickname != null && user!.nickname!.trim().isNotEmpty) {
      _nicknameController.text = user.nickname!;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (file == null || !mounted) {
      return;
    }

    setState(() {
      _imagePath = file.path;
    });
  }

  void _goToPhotoStep() {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 먼저 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _step = 1;
    });
  }

  void _goToBioStep() {
    setState(() {
      _step = 2;
    });
  }

  Future<void> _completeSetup() async {
    if (_isSubmitting) return;

    final nickname = _nicknameController.text.trim();
    final bio = _bioController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }
    if (bio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('한 줄 소개를 입력해주세요.')),
      );
      return;
    }
    if (bio.length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('한 줄 소개는 60자 이내로 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authViewModelProvider.notifier).completeProfileSetup(
            nickname: nickname,
            bio: bio,
            profileImagePath: _imagePath,
          );

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 설정 중 오류가 발생했어요: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AuthScaffold(
      children: [
        if (_step > 0)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
            onPressed: () {
              setState(() {
                _step = _step - 1;
              });
            },
          )
        else
          const SizedBox(height: 48),
        AuthHeader(
          title: _step == 0
              ? '닉네임 설정'
              : _step == 1
                  ? '프로필 사진 설정'
                  : '한 줄 소개 작성',
          subtitle: _step == 0
              ? '닉네임부터 설정해주세요.'
              : _step == 1
                  ? '원하는 프로필 이미지를 등록해보세요.'
                  : '마지막으로 나를 소개하는 한 줄을 적어주세요.',
        ),
        const Spacer(),
        if (_step == 0) ...[
          AuthTextField(
            controller: _nicknameController,
            hintText: '닉네임',
            prefixIcon: Icons.alternate_email,
          ),
          const SizedBox(height: 18),
          AuthButton(
            text: '다음',
            onTap: _goToPhotoStep,
          ),
        ] else if (_step == 1) ...[
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightGrey,
                border: Border.all(color: AppTheme.surfaceColor, width: 1),
                image: _imagePath == null
                    ? null
                    : DecorationImage(
                        image: FileImage(File(_imagePath!)),
                        fit: BoxFit.cover,
                      ),
              ),
              child: _imagePath == null
                  ? const Icon(Icons.add_a_photo_outlined, size: 34)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _pickProfileImage,
            child: const Text('사진 선택'),
          ),
          const SizedBox(height: 8),
          AuthButton(
            text: '다음',
            onTap: _goToBioStep,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _goToBioStep,
            child: const Text('지금은 건너뛰기'),
          ),
        ] else ...[
          AuthTextField(
            controller: _bioController,
            hintText: '한 줄 소개를 입력해주세요',
            prefixIcon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _bioController,
              builder: (context, value, _) {
                final length = value.text.trim().length;
                return Text(
                  '$length/60',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: length > 60
                            ? Colors.redAccent
                            : AppTheme.authTextGray,
                        fontSize: 12,
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AuthButton(
            text: '완료',
            isLoading: _isSubmitting,
            onTap: _completeSetup,
          ),
        ],
        const Spacer(flex: 2),
      ],
    );
  }
}
