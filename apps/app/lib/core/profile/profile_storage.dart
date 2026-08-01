import 'dart:convert';

import 'package:app/core/storage/secure_storage_provider.dart';
import 'package:app/features/session/domain/user_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_storage.g.dart';

const _profileKey = 'user_profile';

@riverpod
Future<UserProfile?> userProfile(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return loadProfile(storage);
}

// Samodzielne funkcje eksportowane osobno
Future<void> saveProfile(
  FlutterSecureStorage storage,
  UserProfile profile,
) async {
  await storage.write(key: _profileKey, value: jsonEncode(profile.toJson()));
}

Future<UserProfile?> loadProfile(FlutterSecureStorage storage) async {
  final raw = await storage.read(key: _profileKey);
  if (raw == null || raw.isEmpty) {
    return null;
  }

  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return UserProfile.fromJson(decoded);
}

Future<void> clearProfile(FlutterSecureStorage storage) async {
  await storage.delete(key: _profileKey);
}
