import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/feed_view_mode_provider.dart';

class FeedToggleHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme
          .backgroundColor, // Ensure opacity so content doesn't show through
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: const _ToggleButtons(),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _ToggleButtons extends ConsumerWidget {
  const _ToggleButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGrid = ref.watch(isGridModeProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => ref.read(isGridModeProvider.notifier).state = false,
          icon: Icon(
            Icons.view_agenda_outlined, // List view icon
            color: isGrid ? AppTheme.textSecondary : AppTheme.primaryColor,
          ),
        ),
        IconButton(
          onPressed: () => ref.read(isGridModeProvider.notifier).state = true,
          icon: Icon(
            Icons.grid_view_outlined, // Grid view icon
            color: isGrid ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
