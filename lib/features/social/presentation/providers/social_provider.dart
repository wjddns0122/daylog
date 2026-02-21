import 'package:daylog/features/auth/domain/models/user_model.dart';
import 'package:daylog/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:daylog/features/social/data/repositories/social_repository_impl.dart';
import 'package:daylog/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl();
});

final socialSearchQueryProvider = StateProvider<String>((ref) => '');

class RecentSearchUsersNotifier extends StateNotifier<List<String>> {
  RecentSearchUsersNotifier() : super(const []) {
    _load();
  }

  static const _storageKey = 'social.recent_search_user_ids';
  static const _maxItems = 12;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_storageKey) ?? const [];
  }

  Future<void> addUser(String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return;

    final deduped = [
      trimmed,
      ...state.where((id) => id != trimmed),
    ];
    final next = deduped.take(_maxItems).toList(growable: false);
    state = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, next);
  }

  Future<void> clear() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> removeUser(String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return;

    final next = state.where((id) => id != trimmed).toList(growable: false);
    state = next;

    final prefs = await SharedPreferences.getInstance();
    if (next.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setStringList(_storageKey, next);
  }
}

final recentSearchUsersProvider =
    StateNotifierProvider<RecentSearchUsersNotifier, List<String>>((ref) {
  return RecentSearchUsersNotifier();
});

final socialSearchProvider = FutureProvider<List<UserModel>>((ref) async {
  final query = ref.watch(socialSearchQueryProvider).trim();
  if (query.isEmpty) {
    return const [];
  }

  final repository = ref.watch(socialRepositoryProvider);
  return repository.searchUsers(query);
});

final relationshipProvider =
    StreamProvider.family<RelationshipState, String>((ref, targetUserId) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchRelationship(targetUserId);
});

final incomingFollowRequestsProvider =
    StreamProvider<List<FollowRequestItem>>((ref) {
  final authState = ref.watch(authViewModelProvider);
  if (authState.valueOrNull == null) {
    return const Stream.empty();
  }
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchIncomingRequests();
});

final followersProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchFollowers(userId);
});

final followingProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.watchFollowing(userId);
});
