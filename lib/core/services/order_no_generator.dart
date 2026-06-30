import 'dart:math';
import 'package:intl/intl.dart';

class OrderNoGenerator {
  static final _random = Random();

  static String generate(String prefix) {
    final now = DateTime.now();
    final ts = DateFormat('yyyyMMddHHmmss').format(now);
    final suffix = _random
        .nextInt(36 * 36)
        .toRadixString(36)
        .toUpperCase()
        .padLeft(2, '0');
    return '$prefix$ts-$suffix';
  }
}
