import 'package:daylog/features/feed/domain/entities/feed_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final resultScreenLaunchUrlProvider =
    Provider<Future<bool> Function(Uri)>((ref) => launchUrl);

class ResultScreen extends HookConsumerWidget {
  const ResultScreen({super.key, required this.post});

  final FeedEntity post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launch = ref.read(resultScreenLaunchUrlProvider);

    final curationText = useMemoized(
      () => _resolveCurationText(post),
      [post.id, post.aiCuration, post.content],
    );
    final musicTitle = useMemoized(
      () => _resolveMusicTitle(post),
      [post.id, post.musicTitle],
    );
    final musicUrl = useMemoized(
      () => _resolveMusicUrl(post),
      [post.id, post.musicUrl],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFD4D4D4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF474747)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/logo_header.png',
          height: 30,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'Complete',
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 32,
                        color: Color(0xFF2B2A27),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Image correction complete!',
                      style: const TextStyle(
                        fontFamily: 'System',
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _PhotoView(imageUrl: post.url),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  '추천 BGM : $musicTitle',
                  style: const TextStyle(
                    fontFamily: 'System',
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        curationText,
                        style: const TextStyle(
                          fontFamily:
                              'System', // Or Georgia if preferred for curation
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons
                            .copyright, // Placeholder for logo icon if not available
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const TextField(
                        maxLines: 2,
                        decoration: InputDecoration.collapsed(
                          hintText:
                              '사진을 한문장으로 표현해주세요\n(ex) "오늘의 최고의 순간을 담은 사진 한장"',
                          hintStyle: TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF24201B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF3B2D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.ondemand_video_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            musicTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            musicUrl == null
                                ? 'No curated music yet.'
                                : 'Tap to open on YouTube',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: musicUrl == null
                          ? null
                          : () => _openMusicLink(context, launch, musicUrl),
                      tooltip: 'Open YouTube',
                      color: Colors.white,
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _shareToInstagramStory(context, launch),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF37322A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text(
                  'Share to Instagram Stories',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMusicLink(
    BuildContext context,
    Future<bool> Function(Uri) launch,
    Uri? musicUrl,
  ) async {
    if (musicUrl == null) {
      return;
    }

    final success = await launch(musicUrl);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open YouTube link.')),
      );
    }
  }

  Future<void> _shareToInstagramStory(
    BuildContext context,
    Future<bool> Function(Uri) launch,
  ) async {
    final deepLink = Uri.parse('instagram://story-camera');
    final webFallback = Uri.parse('https://www.instagram.com/create/story/');

    final opened = await launch(deepLink);
    if (!opened) {
      await launch(webFallback);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instagram opened. Add your memory to Story.'),
        ),
      );
    }
  }
}

class _PhotoView extends StatelessWidget {
  const _PhotoView({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _emptyPhotoPlaceholder();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: const Color(0xFFB9B0A2),
        ),
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emptyPhotoPlaceholder(),
        ),
      ],
    );
  }

  Widget _emptyPhotoPlaceholder() {
    return Container(
      color: const Color(0xFFB8AFA0),
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          size: 56,
          color: Color(0xFF6A6258),
        ),
      ),
    );
  }
}

String _resolveCurationText(FeedEntity post) {
  if (post.aiCuration != null && post.aiCuration!.trim().isNotEmpty) {
    return post.aiCuration!.trim();
  }

  if (post.content.trim().isNotEmpty) {
    return post.content.trim();
  }

  return 'A quiet light lingers in this frame, like a small promise kept.';
}

String _resolveMusicTitle(FeedEntity post) {
  if (post.musicTitle != null && post.musicTitle!.trim().isNotEmpty) {
    return post.musicTitle!.trim();
  }

  return 'Curated soundtrack';
}

Uri? _resolveMusicUrl(FeedEntity post) {
  final raw = post.musicUrl;
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  return Uri.tryParse(raw.trim());
}
