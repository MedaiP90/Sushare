import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/local_user.dart';
import '../../domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, LocalUser?>(() => ProfileViewModel());

class ProfileViewModel extends AsyncNotifier<LocalUser?> {
  @override
  Future<LocalUser?> build() async {
    final repo = ref.read(userRepositoryProvider);
    return repo.getLocalUser();
  }

  Future<void> createProfile({
    required String username,
    required String firstName,
    required String lastName,
    String? profilePicturePath,
  }) async {
    final repo = ref.read(userRepositoryProvider);
    final user = LocalUser(
      id: const Uuid().v4(),
      username: username,
      firstName: firstName,
      lastName: lastName,
      profilePicturePath: profilePicturePath,
      avatarColorValue: _generateAvatarColor(username),
      createdAt: DateTime.now(),
    );
    await repo.saveLocalUser(user);
    state = AsyncValue.data(user);
  }

  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? profilePicturePath,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      username: username ?? currentUser.username,
      firstName: firstName ?? currentUser.firstName,
      lastName: lastName ?? currentUser.lastName,
      profilePicturePath: profilePicturePath ?? currentUser.profilePicturePath,
    );

    final repo = ref.read(userRepositoryProvider);
    await repo.updateLocalUser(updatedUser);
    state = AsyncValue.data(updatedUser);
  }

  int _generateAvatarColor(String username) {
    final colors = [
      0xFFE57373, 0xFF81C784, 0xFF64B5F6, 0xFFFFD54F,
      0xFFBA68C8, 0xFF4DB6AC, 0xFFFF8A65, 0xFFA1887F,
    ];
    final hash = username.hashCode.abs();
    return colors[hash % colors.length];
  }
}
