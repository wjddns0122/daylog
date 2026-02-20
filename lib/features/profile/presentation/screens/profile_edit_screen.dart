import 'dart:io';

import 'package:daylog/core/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  static final RegExp _nicknameRegExp = RegExp(r'^[A-Za-z0-9._-]+$');
  static const int _nicknameMinLength = 3;
  static const int _nicknameMaxLength = 20;

  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSaving = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).valueOrNull;
    if (user != null) {
      _nicknameController.text = user.nickname ?? '';
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _selectedImagePath = picked.path;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final nickname = _nicknameController.text.trim();
    final bio = _bioController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }
    if (!_nicknameRegExp.hasMatch(nickname)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임은 영어, 숫자, 특수기호(._-)만 입력할 수 있어요.')),
      );
      return;
    }
    if (nickname.length < _nicknameMinLength ||
        nickname.length > _nicknameMaxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임은 3자 이상 20자 이하로 입력해주세요.')),
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
      _isSaving = true;
    });

    try {
      await ref.read(authViewModelProvider.notifier).completeProfileSetup(
            nickname: nickname,
            bio: bio,
            profileImagePath: _selectedImagePath,
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      String message = '프로필 저장 중 오류가 발생했어요.';
      if (e is FirebaseAuthException) {
        message = switch (e.code) {
          'nickname-already-in-use' => '이미 사용 중인 닉네임이에요.',
          'invalid-nickname-format' => '닉네임은 영어, 숫자, 특수기호(._-)만 사용할 수 있어요.',
          'invalid-nickname-length' => '닉네임은 3자 이상 20자 이하로 입력해주세요.',
          _ => e.message ?? message,
        };
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).valueOrNull;
    final currentPhotoUrl = user?.photoUrl;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('프로필 편집'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ── Profile Photo ──
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _selectedImagePath != null
                        ? FileImage(File(_selectedImagePath!))
                        : (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty
                            ? NetworkImage(currentPhotoUrl) as ImageProvider
                            : null),
                    child: (_selectedImagePath == null &&
                            (currentPhotoUrl == null ||
                                currentPhotoUrl.isEmpty))
                        ? const Icon(Icons.person,
                            size: 40, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.backgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Nickname ──
          const Text(
            '닉네임(영문, 밑줄(_)만 가능)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              hintText: '영문과 밑줄(_)만 입력 가능 (특수문자 불가)',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Bio ──
          const Text(
            '한 줄 소개',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            minLines: 2,
            maxLines: 3,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: '한 줄 소개를 입력해주세요',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Save Button ──
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장하기'),
          ),
        ],
      ),
    );
  }
}
