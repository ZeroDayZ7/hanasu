import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_provider.g.dart';

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  const androidOptions = AndroidOptions(resetOnError: true);
  const iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  return const FlutterSecureStorage(
    aOptions: androidOptions,
    iOptions: iosOptions,
  );
}

// Samodzielne funkcje w Darcie (top-level functions)
Future<void> secureStorageWrite(
  FlutterSecureStorage storage,
  String key,
  String value,
) async {
  await storage.write(key: key, value: value);
}

Future<String?> secureStorageRead(
  FlutterSecureStorage storage,
  String key,
) async {
  return await storage.read(key: key);
}

Future<void> secureStorageDelete(
  FlutterSecureStorage storage,
  String key,
) async {
  await storage.delete(key: key);
}
