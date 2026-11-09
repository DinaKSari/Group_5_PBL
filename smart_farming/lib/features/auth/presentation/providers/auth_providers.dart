import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/demo_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const DemoAuthRepository();
});
