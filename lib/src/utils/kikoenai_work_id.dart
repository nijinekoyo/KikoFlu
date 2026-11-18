/// Bridges Kikoenai's string IDs with the app's persisted integer work keys.
/// Positive RJ keys stay unchanged. Negative keys reserve a separate namespace
/// for Fanza and BJ works, so equal numeric parts never share downloads/history.
class KikoenaiWorkId {
  static int fromJson(Object? value) {
    if (value is num) return value.toInt();
    final text = value.toString();
    final match = RegExp(
      r'^(d_?|BJ|RJ)?(\d+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) throw FormatException('Invalid work ID', value);
    final number = int.parse(match.group(2)!);
    return switch (match.group(1)?.toLowerCase()) {
      'd' || 'd_' => -(number * 10 + 1),
      'bj' => -(number * 10 + 2),
      _ => number,
    };
  }

  static String serverId(int id, {bool pad = true}) {
    if (id >= 0) return pad ? _padded(id) : '$id';
    final number = -id ~/ 10;
    return switch (-id % 10) {
      1 => 'd$number',
      2 => 'BJ${_padded(number)}',
      _ => throw FormatException('Invalid internal work key', id),
    };
  }

  static String displayId(int id) {
    final code = serverId(id);
    return id >= 0 ? 'RJ$code' : code;
  }

  static String _padded(int id) => '$id'.padLeft(id < 1000000 ? 6 : 8, '0');
}
