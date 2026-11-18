import '../../../../core/failures.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  UserProfile? get currentProfile;

  Future<({bool cleared, Failure? failure})> clearPhoto();
}
