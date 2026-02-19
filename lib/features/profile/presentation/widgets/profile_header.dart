import 'package:daylog/core/theme/app_theme.dart';

import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String handle;
  final String bio;
  final String joinDate;
  final int postCount;
  final int followerCount;
  final int followingCount;
  final String? avatarUrl;
  final VoidCallback? onEditProfile;
  final VoidCallback? onTapFollowers;
  final VoidCallback? onTapFollowing;
  final bool showEditProfileButton;

  const ProfileHeader({
    super.key,
    required this.handle,
    required this.bio,
    required this.joinDate,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    this.avatarUrl,
    this.onEditProfile,
    this.onTapFollowers,
    this.onTapFollowing,
    this.showEditProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Avatar + Stats
          Row(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightGrey,
                  border: Border.all(color: AppTheme.surfaceColor, width: 1),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Icon(Icons.person,
                        size: 40, color: AppTheme.textSecondary)
                    : null,
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, postCount, '마이로그'),
                    _buildStatItem(
                      context,
                      followerCount,
                      '팔로워',
                      onTap: onTapFollowers,
                    ),
                    _buildStatItem(
                      context,
                      followingCount,
                      '팔로잉',
                      onTap: onTapFollowing,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bio Section
          // Nickname/Handle usually goes above bio if it's the "Name" field,
          // but looking at the design/request: "@Daylog_1234" is often the handle at top,
          // or displayed here. The design image shows "@Daylog_1234" at the very top (AppBar title usually?)
          // or just above the bio.
          // Let's assume the AppBar has the "Title" and here we might have a Name or just Bio.
          // The request said: "Nickname left @... and bio".

          // If the AppBar title is "My Profile", we might want the handle here.
          // But the design image shows "< @Daylog_1234" in the AppBar area.
          // I will put the handle in the AppBar in the Screen, and here just the Bio?
          // Or per instructions: "Nickname left @..."

          // Re-reading request: "Use @ for nickname left..."
          // Let's put the bio text provided in the design.

          Text(
            bio,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          // Join Date
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                joinDate,
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          if (showEditProfileButton) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: onEditProfile,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('프로필 편집',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    int count,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
