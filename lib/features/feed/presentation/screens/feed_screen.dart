import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the new StreamNotifierProvider
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
      data: (feedInternal) {
        if (feedInternal.isEmpty) {
          return const Center(child: Text('No photos yet. Go upload some!'));
        }
        return ListView.builder(
          itemCount: feedInternal.length,
          itemBuilder: (context, index) {
            final item = feedInternal[index];
            return FeedCard(item: item);
          },
        );
      },
      error: (err, stack) => Center(child: Text('Error: $err')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
