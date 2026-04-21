import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';

class ProfileData {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String userType;
  final String? bio;
  final double scoreReputation;
  final DateTime createdAt;

  const ProfileData({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.userType,
    this.bio,
    required this.scoreReputation,
    required this.createdAt,
  });

  factory ProfileData.fromJson(Map<String, dynamic> j) => ProfileData(
    id:              j['id'] as String,
    fullName:        j['full_name'] as String,
    email:           j['email'] as String,
    avatarUrl:       j['avatar_url'] as String?,
    userType:        j['user_type'] as String,
    bio:             j['bio'] as String?,
    scoreReputation: (j['score_reputation'] as num).toDouble(),
    createdAt:       DateTime.parse(j['created_at'] as String),
  );

  String get userTypeLabel {
    const map = {
      'vendedor':   'Vendedor',
      'comprador':  'Comprador',
      'indicador':  'Indicador',
      'investidor': 'Investidor',
    };
    return map[userType] ?? userType;
  }

  int get membershipDays => DateTime.now().difference(createdAt).inDays;
}

class ProfileNotifier extends AsyncNotifier<ProfileData?> {
  @override
  Future<ProfileData?> build() => _fetch();

  Future<ProfileData?> _fetch() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;

    final data = await ref.read(supabaseClientProvider)
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return ProfileData.fromJson(data);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileData?>(ProfileNotifier.new);
