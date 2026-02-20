import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:daylog/features/camera/presentation/screens/result_screen.dart';
import 'package:daylog/features/feed/domain/entities/feed_entity.dart';
import 'package:daylog/features/feed/presentation/providers/feed_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import '../../../../core/theme/app_theme.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.enableHeaderMarquee = true});

  final bool enableHeaderMarquee;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  bool _isLoadingPosts = false;
  String? _loadError;
  Map<DateTime, FeedEntity> _postsByDate = {};
  StreamSubscription<List<FeedEntity>>? _postsSubscription;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToPostsForFocusedMonth();
    });
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                _buildAnimatedHeader(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Today_log',
                        style: GoogleFonts.lora(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Show me your day today',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A7A7A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildMonthNavigation(),
                      const SizedBox(height: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildCalendarContainer(),
                          Positioned(
                            bottom: -100,
                            right: -40,
                            child: IgnorePointer(
                              child: _buildFloatingGalleryIcon(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 130), // Nav bar clearance
                    ],
                  ),
                ),
              ],
            ),
          ],
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
          tooltip: 'Open notifications',
          icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          tooltip: 'Open settings',
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
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              height: 50,
              child: widget.enableHeaderMarquee
                  ? Marquee(
                      text: 'A Day\'s Photos, 6 Hours of Excitement       ',
                      style: GoogleFonts.archivoBlack(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      blankSpace: 20,
                      velocity: 50,
                      startPadding: 0,
                    )
                  : Text(
                      'A Day\'s Photos, 6 Hours of Excitement',
                      style: GoogleFonts.archivoBlack(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
            ),
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

  Widget _buildFloatingGalleryIcon() {
    return Transform.rotate(
      angle: 0.3,
      child: Opacity(
        opacity: 0.8,
        child: Image.asset(
          'assets/images/logo2.png',
          width: 135,
          height: 135,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildCalendarContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDayHeaders(),
          const SizedBox(height: 12),
          if (_isLoadingPosts)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF4D4D4D),
                backgroundColor: Color(0xFFD8D8D8),
              ),
            ),
          _buildCalendarGrid(),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _loadError!,
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: const Color(0xFF888888),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                size: 16, color: Colors.black54),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat('MMMM').format(_focusedDay),
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.black54),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (day) => SizedBox(
              width: 30,
              child: Center(
                child: Text(
                  day,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final weekdayOffset = firstDayOfMonth.weekday % 7;
    final totalCells = daysInMonth + weekdayOffset;

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayIndex = index - weekdayOffset;
        if (dayIndex < 0) {
          return const SizedBox.shrink();
        }

        final day = dayIndex + 1;
        final currentDayDate =
            DateTime(_focusedDay.year, _focusedDay.month, day);
        final isSelected = _selectedDay != null &&
            DateUtils.isSameDay(_selectedDay, currentDayDate);
        final isToday = DateUtils.isSameDay(DateTime.now(), currentDayDate);
        final post = _postsByDate[currentDayDate];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = currentDayDate;
            });

            if (post != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultScreen(post: post),
                ),
              );
            }
          },
          child: post == null
              ? _buildDayNumberCell(
                  day: day,
                  isSelected: isSelected,
                  isToday: isToday,
                )
              : _buildThumbnailCell(
                  day: day,
                  post: post,
                  isSelected: isSelected,
                  isToday: isToday,
                ),
        );
      },
    );
  }

  Widget _buildDayNumberCell({
    required int day,
    required bool isSelected,
    required bool isToday,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth * 0.35;
        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.black87 : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: Colors.black54, width: 1)
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: GoogleFonts.lora(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnailCell({
    required int day,
    required FeedEntity post,
    required bool isSelected,
    required bool isToday,
  }) {
    final borderColor = isSelected
        ? const Color(0xFF222222)
        : isToday
            ? const Color(0xFF5B5B5B)
            : const Color(0xFFCBCBCB);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final dateFontSize = size * 0.25;
        final dateBadgePaddingH = size * 0.1;
        final dateBadgePaddingV = size * 0.05;
        final dateBadgeMargin = size * 0.08;
        final borderRadius = size * 0.25;

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFFD6D1C8)),
              CachedNetworkImage(
                imageUrl: post.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildThumbnailPlaceholder(day),
                errorWidget: (_, __, ___) => _buildThumbnailPlaceholder(day),
              ),
              Container(color: const Color(0xFF4F4332).withValues(alpha: 0.14)),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border:
                      Border.all(color: borderColor, width: isSelected ? 2 : 1),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: EdgeInsets.all(dateBadgeMargin),
                  padding: EdgeInsets.symmetric(
                    horizontal: dateBadgePaddingH,
                    vertical: dateBadgePaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(borderRadius * 0.6),
                  ),
                  child: Text(
                    '$day',
                    style: GoogleFonts.lora(
                      fontSize: dateFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF2EEE8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnailPlaceholder(int day) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: const Color(0xFFC5BEB2),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: GoogleFonts.lora(
              fontSize: constraints.maxWidth * 0.35,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF625B51),
            ),
          ),
        );
      },
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
    });
    _subscribeToPostsForFocusedMonth();
  }

  void _subscribeToPostsForFocusedMonth() {
    // Cancel previous subscription
    _postsSubscription?.cancel();

    String? userId;
    try {
      userId = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      userId = null;
    }
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _postsByDate = {};
        _loadError = null;
        _isLoadingPosts = false;
      });
      return;
    }

    setState(() {
      _isLoadingPosts = true;
      _loadError = null;
    });

    final repository = ref.read(feedRepositoryProvider);
    final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);

    _postsSubscription = repository
        .watchUserPostsByDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    )
        .listen(
      (posts) {
        if (!mounted) return;

        final mappedPosts = <DateTime, FeedEntity>{};
        for (final post in posts) {
          final dayKey = DateTime(
            post.timestamp.year,
            post.timestamp.month,
            post.timestamp.day,
          );
          final existing = mappedPosts[dayKey];
          if (existing == null || post.timestamp.isAfter(existing.timestamp)) {
            mappedPosts[dayKey] = post;
          }
        }

        setState(() {
          _postsByDate = mappedPosts;
          _isLoadingPosts = false;
          _loadError = null;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _postsByDate = {};
          _isLoadingPosts = false;
          _loadError = 'Could not load memories for this month.';
        });
      },
    );
  }
}
