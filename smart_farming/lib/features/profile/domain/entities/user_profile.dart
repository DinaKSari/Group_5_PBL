class UserProfile {
  const UserProfile({this.name, this.email, this.photoUrl});

  final String? name;
  final String? email;
  final String? photoUrl;

  String get displayName {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;

    final userEmail = email;
    if (userEmail != null && userEmail.contains('@')) {
      final prefix = userEmail.split('@').first;
      if (prefix.isNotEmpty) {
        return '${prefix[0].toUpperCase()}${prefix.substring(1)}';
      }
    }
    return 'Petani Selada';
  }

  String get displayEmail => email?.trim().isNotEmpty == true
      ? email!.trim()
      : 'petani@smartfarming.com';
}
