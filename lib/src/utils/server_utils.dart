import 'kikoenai_work_id.dart';

class ServerUtils {
  static String coverUrl(String host, int id, String token) => withAuthToken(
        '${normalizeHost(host)}/api/cover/${KikoenaiWorkId.serverId(id, pad: isSessionCredential(token))}',
        token,
      );

  /// Kikoenai issues a 32-byte opaque session secret; older servers use JWTs.
  static bool isSessionCredential(String? token) =>
      token != null && RegExp(r'^[a-f0-9]{64}$').hasMatch(token);

  static String normalizeHost(String host) {
    var value = host.trim().replaceFirst(RegExp(r'/+$'), '');
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      final hostname = Uri.tryParse('http://$value')?.host ?? '';
      final local = hostname == 'localhost' ||
          hostname == '::1' ||
          hostname.startsWith('127.') ||
          hostname.startsWith('10.') ||
          hostname.startsWith('192.168.') ||
          RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(hostname);
      value = '${local ? 'http' : 'https'}://$value';
    }
    return value;
  }

  /// Root-relative media URLs already contain the server's deployment prefix.
  static String resolveMediaUrl(String host, String url) =>
      Uri.parse('${normalizeHost(host)}/').resolve(url).toString();

  static String withAuthToken(String url, String token) {
    final uri = Uri.parse(url);
    if (isSessionCredential(token)) {
      if (!uri.queryParameters.containsKey('token')) return url;
      final query = Map<String, String>.from(uri.queryParameters)
        ..remove('token');
      if (query.isNotEmpty) return uri.replace(queryParameters: query).toString();
      final queryStart = url.indexOf('?');
      final fragmentStart = url.indexOf('#', queryStart);
      return url.substring(0, queryStart) +
          (fragmentStart < 0 ? '' : url.substring(fragmentStart));
    }
    if (token.isEmpty || uri.queryParameters.containsKey('token')) return url;
    return uri.replace(
        queryParameters: {...uri.queryParameters, 'token': token}).toString();
  }

  static const String officialHostKeyword = 'api.asmr';
  static const String defaultRemoteHost = 'https://api.asmr-200.com';
  static const String defaultLocalHost = 'localhost:8888';

  static const List<String> preferredHosts = [
    'api.asmr-200.com',
    'api.asmr.one',
    'api.asmr-100.com',
    'api.asmr-300.com',
  ];

  /// Checks if the provided host string corresponds to the official server.
  static bool isOfficialServer(String? host) {
    if (host == null || host.isEmpty) return false;
    return host.contains(officialHostKeyword);
  }
}
