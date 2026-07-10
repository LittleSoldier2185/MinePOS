class StaffMember {
  const StaffMember({
    required this.username,
    required this.role,
    required this.active,
    required this.createdAt,
  });

  final String username;
  final String role; // "owner" | "manager" | "worker"
  final bool active;
  final DateTime createdAt;

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        username: json['username'] as String,
        role: json['role'] as String,
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
