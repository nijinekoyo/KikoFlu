import '../utils/server_utils.dart';

/// Wire-format conversion for Rivers47/Kikoenai. Kept separate from legacy API
/// handling so a session login selects the new protocol without a user setting.
class KikoenaiProtocol {
  static String order(String value) => switch (value) {
        'create_date' || 'download_date' => 'created_at',
        'work_id' => 'id',
        'nsfw' => 'release',
        _ => value,
      };

  static ({String filter, int nsfw}) search(String keyword) {
    var nsfw = 0;
    final filter = keyword.replaceAllMapped(
      RegExp(r'\$(-?)([a-zA-Z_]+):([^$]+)\$'),
      (match) {
        final exclude = match[1] == '-';
        final field = match[2]!;
        final value = match[3]!;
        if (field == 'age') {
          if (value == 'general') nsfw = exclude ? 2 : 1;
          if (value == 'adult') nsfw = exclude ? 1 : 2;
          return '';
        }
        // The UI's rj conditions and metadata chips use exact matches.
        return '${exclude ? '-' : ''}${field == 'rj' ? 'id' : field}:"${value.replaceAll('"', ' ')}\$"';
      },
    ).trim();
    return (filter: filter, nsfw: nsfw);
  }

  static List<dynamic> tracks(dynamic response, String host) {
    final tree = response is Map ? response['tree'] : response;
    if (tree is! List) throw const FormatException('Invalid track tree');
    return tree.map((item) {
      final node = Map<String, dynamic>.from(item as Map);
      if (node['children'] is List) {
        node['children'] = tracks(node['children'], host);
      }
      // Existing playback, subtitle and download code uses hash as the file key
      // and as a fallback media route. Encode each path segment exactly once.
      if (node['trackId'] is String) {
        node['hash'] = (node['trackId'] as String)
            .split('/')
            .map(Uri.encodeComponent)
            .join('/');
      }
      for (final key in ['mediaStreamUrl', 'mediaDownloadUrl']) {
        if (node[key] is String) {
          node[key] = ServerUtils.resolveMediaUrl(host, node[key] as String);
        }
      }
      return node;
    }).toList();
  }
}
