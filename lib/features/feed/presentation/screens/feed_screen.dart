import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../../../features/likes/presentation/screens/like_screen.dart';
import 'package:marquee/marquee.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../camera/presentation/screens/camera_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../camera/presentation/widgets/developing_card.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_card.dart';
import '../widgets/feed_grid_item.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _currentIndex = 0;
  bool _isGridMode = false;

  final List<Widget> _screens = [
    const SizedBox.shrink(), // Index 0 handled by CustomScrollView
    const CalendarScreen(),
    const CameraScreen(),
    const LikeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: _currentIndex == 0
            ? CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  _buildAnimatedHeader(),
                  _buildToggleBar(),
                  _buildFeedSlivers(),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                ],
              )
            : IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Community',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.add_rounded,
                  label: '',
                  index: 2,
                  isFab: true,
                ),
                _buildNavItem(
                  icon: Icons.favorite_rounded,
                  label: 'Likes',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      title: Image.asset(
        'assets/images/logo_header.png',
        height: 30,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: 250,
        width: double.infinity,
        color: AppTheme.backgroundColor,
        child: Stack(
          children: [
            // Moving Background Text
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              height: 50,
              child: Marquee(
                text: 'A Day\'s Photos, 6 Hours of Excitement       ',
                style: GoogleFonts.archivoBlack(
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                blankSpace: 20.0,
                velocity: 50.0,
                startPadding: 0.0,
              ),
            ),
            // 3D Logo (Foreground)
            Positioned(
              top: 40,
              left: 115,
              child: Transform.rotate(
                angle: 14.51 * 3.1415926535 / 180,
                child: SvgPicture.asset(
                  'assets/svgs/logo.svg',
                  width: 174,
                  height: 166,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBar() {
    final activeColor = const Color(0xFF414141);
    final inactiveColor = const Color(0xFF999999);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(right: 20, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.view_agenda,
                color: !_isGridMode ? activeColor : inactiveColor,
              ),
              onPressed: () => setState(() => _isGridMode = false),
            ),
            IconButton(
              icon: Icon(
                Icons.grid_view,
                color: _isGridMode ? activeColor : inactiveColor,
              ),
              onPressed: () => setState(() => _isGridMode = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedSlivers() {
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
      data: (feedInternal) {
        if (feedInternal.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No photos yet. Go upload some!')),
            ),
          );
        }

        if (_isGridMode) {
          // Sort by likeCount descending for Grid Mode as per design rules
          final sortedFeed = [...feedInternal]
            ..sort((a, b) => b.likedBy.length.compareTo(a.likedBy.length));

          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = sortedFeed[index];
                return FeedGridItem(item: item);
              },
              childCount: sortedFeed.length,
            ),
          );
        } else {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = feedInternal[index];
              if (item.status == 'PENDING') {
                return DevelopingCard(item: item);
              }
              return FeedCard(item: item);
            }, childCount: feedInternal.length),
          );
        }
      },
      error: (err, stack) =>
          SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isFab = false,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : Colors.grey;

    if (isFab) {
      return GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
