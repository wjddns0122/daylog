import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../feed/domain/entities/feed_entity.dart';

class DevelopingCard extends StatefulWidget {
  final FeedEntity item;

  const DevelopingCard({super.key, required this.item});

  @override
  State<DevelopingCard> createState() => _DevelopingCardState();
}

class _DevelopingCardState extends State<DevelopingCard> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() {
    if (widget.item.releaseTime == null) return;

    final now = DateTime.now();
    final remaining = widget.item.releaseTime!.difference(now);

    if (remaining.isNegative) {
      _timer.cancel();
      setState(() {
        _remainingTime = Duration.zero;
      });
    } else {
      setState(() {
        _remainingTime = remaining;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // Darkroom vibes
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background "Blur" Effect (Mock)
          Center(
            child: Icon(
              Icons.camera,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Developing...',
                style: GoogleFonts.archivoBlack(
                  fontSize: 24,
                  color: AppTheme.accentColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your memory is being processed.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.accentColor, width: 2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _formatDuration(_remainingTime),
                  style: GoogleFonts.robotoMono(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Unlock at ${widget.item.releaseTime?.toLocal().toString().split('.')[0] ?? 'Unknown'}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
