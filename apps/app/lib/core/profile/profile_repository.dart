import 'package:app/core/profile/profile_storage.dart';
import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/session/domain/user_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'profile_repository.g.dart';

const _uuid = Uuid();

@riverpod
Future<UserProfile?> userProfileRepository(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return loadProfile(storage);
}

// Samodzielne funkcje operacyjne
Future<UserProfile?> fetchUserProfile(FlutterSecureStorage storage) async {
  return await loadProfile(storage);
}

Future<UserProfile> createOrUpdateNick(
  FlutterSecureStorage storage,
  String nick,
) async {
  final existingProfile = await loadProfile(storage);
  final profile = UserProfile(
    id: existingProfile?.id ?? _uuid.v4(),
    nick: nick,
    createdAt: existingProfile?.createdAt ?? DateTime.now(),
  );

  await saveProfile(storage, profile);
  return profile;
}

Future<void> removeProfile(FlutterSecureStorage storage) async {
  await clearProfile(storage);
}
