import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../services/host_server_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  ref.onDispose(() => AppDatabase.close());
  return AppDatabase();
});

final hostServerServiceProvider = Provider<HostServerService>((ref) {
  final service = HostServerService();
  ref.onDispose(() => service.dispose());
  return service;
});
