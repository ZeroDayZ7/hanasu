import 'dart:math';

String generateRoomCode() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random();
  final result = List.generate(
    5,
    (_) => chars[rand.nextInt(chars.length)],
  ).join();
  return result;
}
