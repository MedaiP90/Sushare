import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../services/host_ble_service.dart';
import '../services/participant_ble_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  ref.onDispose(() => AppDatabase.close());
  return AppDatabase();
});

final hostBleServiceProvider = Provider<HostBleService>((ref) {
  final service = HostBleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final participantBleServiceProvider = Provider<ParticipantBleService>((ref) {
  final service = ParticipantBleService();
  ref.onDispose(() => service.dispose());
  return service;
});
