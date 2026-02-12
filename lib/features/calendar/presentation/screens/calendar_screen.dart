import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import '../../../../core/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
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
                      // Wrap Calendar Container in a Stack to anchor the icon
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildCalendarContainer(),
                          Positioned(
                            bottom: -40,
                            right: 0,
                            child: IgnorePointer(
                              child: _buildFloatingGalleryIcon(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () {
          // Provide back navigation if needed
        },
      ),
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
                  color: Colors.black, // Matched FeedScreen
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                blankSpace: 20.0,
                velocity: 50.0,
                startPadding: 0.0,
              ),
            ),
            // 3D Logo (Foreground) - Matches FeedScreen
            Positioned(
              top: 40,
              left: 115,
              child: Transform.rotate(
                angle: 14.51 * 3.1415926535 / 180,
                child: SvgPicture.asset(
                  'assets/svgs/logo.svg', // Feed uses logo.svg
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
      angle: 0.15,
      child: Opacity(
        opacity: 0.9, // Slight transparency as requested
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
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Dynamic container height
        children: [
          _buildDayHeaders(),
          const SizedBox(height: 12),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                size: 16, color: Colors.black54),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
              });
            },
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
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map((day) => SizedBox(
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
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final int weekdayOffset = firstDayOfMonth.weekday % 7;

    // Calculate EXACT number of cells including offsets, no fixed 42
    final int totalCells = daysInMonth + weekdayOffset;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
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

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = currentDayDate;
            });
          },
          child: Container(
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
