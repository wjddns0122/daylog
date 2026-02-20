import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart'; // Restored

import '../../../../core/theme/app_theme.dart';
import '../../../camera/presentation/widgets/developing_card.dart';
import '../../domain/entities/feed_entity.dart';
import '../providers/feed_provider.dart';
import '../screens/feed_detail_screen.dart';
import '../widgets/feed_card.dart';
import '../widgets/feed_grid_item.dart';
import '../../../social/presentation/providers/social_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool _isGridMode = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _onRefresh(currentUserId),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              _buildAnimatedHeader(),
              _buildToggleBar(),
              ..._buildFeedSlivers(currentUserId),
              // Extra bottom padding so content is not hidden behind the glassmorphic nav bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh(String? currentUserId) async {
    ref.invalidate(feedProvider);
    if (currentUserId != null) {
      ref.invalidate(followingProvider(currentUserId));
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
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
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.person_search_outlined, color: Colors.black),
          onPressed: () => context.push('/search-users'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          onPressed: () => context.push('/settings'),
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

  List<Widget> _buildFeedSlivers(String? currentUserId) {
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
      data: (feedInternal) {
        if (feedInternal.isEmpty) {
          return const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: Text('No photos yet. Go upload some!')),
              ),
            ),
          ];
        }

        if (_isGridMode) {
          // Grid mode remains sorted by like count.
          final sortedFeed = [...feedInternal]
            ..sort((a, b) => b.likedBy.length.compareTo(a.likedBy.length));

          return [
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = sortedFeed[index];
                  return FeedGridItem(
                    item: item,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FeedDetailScreen(
                            posts: sortedFeed,
                            initialPostId: item.id,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: sortedFeed.length,
              ),
            ),
          ];
        } else {
          final sortedAll = [...feedInternal]
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (currentUserId == null) {
            return _buildSectionedFeedSlivers(
              title: '모든 공개 게시글',
              posts: sortedAll,
            );
          }

          final followingAsync = ref.watch(followingProvider(currentUserId));
          return followingAsync.when(
            data: (followingUsers) {
              final followingIds = followingUsers.map((u) => u.uid).toSet();
              final followingPosts = sortedAll
                  .where((post) =>
                      post.userId != null && followingIds.contains(post.userId))
                  .toList();

              final followingPostIds =
                  followingPosts.map((post) => post.id).toSet();
              final remainingPosts = sortedAll
                  .where((post) => !followingPostIds.contains(post.id))
                  .toList();

              final slivers = <Widget>[];
              if (followingPosts.isNotEmpty) {
                slivers.addAll(_buildSectionedFeedSlivers(
                  title: '팔로잉 게시글',
                  posts: followingPosts,
                ));
              }

              slivers.addAll(_buildSectionedFeedSlivers(
                title: '모든 공개 게시글',
                posts: remainingPosts,
              ));

              return slivers;
            },
            loading: () => _buildSectionedFeedSlivers(
              title: '모든 공개 게시글',
              posts: sortedAll,
            ),
            error: (_, __) => _buildSectionedFeedSlivers(
              title: '모든 공개 게시글',
              posts: sortedAll,
            ),
          );
        }
      },
      error: (err, stack) => [
        SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
      ],
      loading: () => const [
        SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  List<Widget> _buildSectionedFeedSlivers({
    required String title,
    required List<FeedEntity> posts,
  }) {
    if (posts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text(
              title,
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF404040),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox.shrink(),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(
            title,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF404040),
            ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = posts[index];
          if (item.status == 'PENDING') {
            return DevelopingCard(item: item);
          }
          return FeedCard(item: item);
        }, childCount: posts.length),
      ),
    ];
  }
}
