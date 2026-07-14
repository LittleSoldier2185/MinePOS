class StaffMember {
  const StaffMember({
    required this.id,
    required this.username,
    required this.role,
    required this.active,
    required this.createdAt,
    this.name,
    this.email,
    this.phone,
    this.avatarBase64,
  });

  final int id;
  final String username;
  final String role; // "owner" | "manager" | "worker"
  final bool active;
  final DateTime createdAt;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatarBase64;

  /// Display name for anywhere only one label fits — the person's real name
  /// when set, falling back to their login username otherwise.
  String get displayName => (name == null || name!.isEmpty) ? username : name!;

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'] as int,
        username: json['username'] as String,
        role: json['role'] as String,
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        name: json['name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        avatarBase64: json['avatarBase64'] as String?,
      );
}
