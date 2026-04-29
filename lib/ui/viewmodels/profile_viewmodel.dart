import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/local_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../widgets/avatar_widget.dart';

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
    required int avatarIconCodePoint,
    required int avatarColorValue,
  }) async {
    final repo = ref.read(userRepositoryProvider);
    final user = LocalUser(
      id: const Uuid().v4(),
      username: username,
      firstName: firstName,
      lastName: lastName,
      avatarIconCodePoint: avatarIconCodePoint,
      avatarColorValue: avatarColorValue,
      createdAt: DateTime.now(),
    );
    await repo.saveLocalUser(user);
    state = AsyncValue.data(user);
  }

  Future<void> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    int? avatarIconCodePoint,
    int? avatarColorValue,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      username: username ?? currentUser.username,
      firstName: firstName ?? currentUser.firstName,
      lastName: lastName ?? currentUser.lastName,
      avatarIconCodePoint: avatarIconCodePoint ?? currentUser.avatarIconCodePoint,
      avatarColorValue: avatarColorValue ?? currentUser.avatarColorValue,
    );

    final repo = ref.read(userRepositoryProvider);
    await repo.updateLocalUser(updatedUser);
    state = AsyncValue.data(updatedUser);
  }

  AvatarData generateAvatarFromUsername(String username) {
    return AvatarData.generateFromUsername(username);
  }
}
