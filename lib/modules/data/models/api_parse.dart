import 'dart:convert';

List<dynamic> decodeJsonList(String body) {
  final decoded = jsonDecode(body);
  if (decoded is List<dynamic>) return decoded;
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'] ?? decoded['items'] ?? decoded['results'];
    if (data is List<dynamic>) return data;
  }
  return const [];
}

T? mapValue<T>(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is T) return v;
  }
  return null;
}

String? mapString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String) return v;
    if (v != null) return v.toString();
  }
  return null;
}

num? mapNum(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
  }
  return null;
}

DateTime? mapDate(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

Map<String, dynamic> asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return {};
}
