import 'package:daylog/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int postCount;
  final int followerCount;
  final int followingCount;

  const ProfileStats({
    super.key,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem(context, postCount, '마이로그'),
        const SizedBox(width: 40),
        _buildStatItem(context, followerCount, '팔로워'),
        const SizedBox(width: 40),
        _buildStatItem(context, followingCount, '팔로잉'),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400, // Inter Regular
            fontSize: 16,
          ),
        ),
        const SizedBox(
            height:
                0), // Line height adjustment in text style usually handles this, closely packed in design
        Text(
          label,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            fontSize: 16, // Matching 16px from Figma
            fontWeight: FontWeight.w400,
            color: AppTheme.primaryColor, // Ensure consistent color
          ),
        ),
      ],
    );
  }
}
