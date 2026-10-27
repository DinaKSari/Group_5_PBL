import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';

/// Satu-satunya tempat wiring implementasi → abstraksi (Dependency Injection).
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});
