import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  String displayName(User? user) {
    if (user == null) return '';
    final meta = user.userMetadata;
    if (meta == null) return '';
    final name = meta['full_name'] ?? meta['name'];
    if (name is String) return name.trim();
    return '';
  }

  String firstName(User? user) {
    final full = displayName(user);
    if (full.isEmpty) return '';
    return full.split(RegExp(r'\s+')).first.trim();
  }

  String initials(User? user) {
    final full = displayName(user);
    if (full.isEmpty) {
      final email = user?.email ?? '';
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }

    final parts = full
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> updateDisplayName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final first = trimmed.split(RegExp(r'\s+')).first.trim();
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': trimmed,
          'name': first,
        },
      ),
    );
  }
}
