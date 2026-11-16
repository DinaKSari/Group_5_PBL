import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository();
});

final currentProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).currentProfile;
});
