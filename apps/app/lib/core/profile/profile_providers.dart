import 'package:app/core/profile/profile_repository.dart';
import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/session/domain/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    final storage = ref.watch(secureStorageProvider);
    return await fetchUserProfile(storage);
  }

  Future<void> updateNick(String nick) async {
    final storage = ref.read(secureStorageProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return await createOrUpdateNick(storage, nick);
    });
  }

  Future<void> clear() async {
    final storage = ref.read(secureStorageProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await removeProfile(storage);
      return null;
    });
  }
}
