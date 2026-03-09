/// Utilities for converting between Supabase (snake_case) JSON and app (camelCase) entities.
library;

/// Recursively converts snake_case keys to camelCase in a map.
/// Used when deserializing Supabase responses to Drift-style entities.
Map<String, dynamic> camelCaseKeys(Map<String, dynamic> map) {
  return map.map((key, value) {
    final newKey = _toCamelCase(key);
    final newValue = value is Map<String, dynamic>
        ? camelCaseKeys(value)
        : value is List
            ? value
                .map((e) =>
                    e is Map<String, dynamic> ? camelCaseKeys(e) : e)
                .toList()
            : value;
    return MapEntry(newKey, newValue);
  });
}

/// Recursively converts camelCase keys to snake_case in a map.
/// Used when serializing entities for Supabase insert/update.
Map<String, dynamic> snakeCaseKeys(Map<String, dynamic> map) {
  return map.map((key, value) {
    final newKey = _toSnakeCase(key);
    final newValue = value is Map<String, dynamic>
        ? snakeCaseKeys(value)
        : value is List
            ? value
                .map((e) =>
                    e is Map<String, dynamic> ? snakeCaseKeys(e) : e)
                .toList()
            : value;
    return MapEntry(newKey, newValue);
  });
}

/// Converts values for Supabase: Drift serializes DateTime as Unix milliseconds;
/// Postgres timestamptz expects ISO 8601 strings. Recursively processes maps/lists.
dynamic _convertDatesForSupabase(dynamic value) {
  if (value is int &&
      value > 1000000000000 &&
      value < 2500000000000) {
    return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
  }
  if (value is Map<String, dynamic>) {
    return value.map((k, v) => MapEntry(k, _convertDatesForSupabase(v)));
  }
  if (value is List) {
    return value.map((e) => _convertDatesForSupabase(e)).toList();
  }
  return value;
}

/// Prepares a map for Supabase: snake_case keys + DateTime as ISO 8601.
Map<String, dynamic> prepareForSupabase(Map<String, dynamic> map) {
  final snake = snakeCaseKeys(map);
  return _convertDatesForSupabase(snake) as Map<String, dynamic>;
}

String _toCamelCase(String s) {
  if (s.isEmpty) return s;
  final parts = s.split('_');
  return parts.first.toLowerCase() +
      parts.skip(1).map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase()).join();
}

String _toSnakeCase(String s) {
  if (s.isEmpty) return s;
  return s.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  ).replaceFirst(RegExp(r'^_'), '');
}
