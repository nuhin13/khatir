import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'auth_repository.dart';

/// The shared [AuthRepository], backed by the app-wide dio client.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioClientProvider)),
);
