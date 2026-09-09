/// Membre de l'équipe marchande (`staff_users`), tel que renvoyé par
/// `GET /auth/merchant/team`.
class TeamMember {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'admin' | 'operator'
  final bool isActive;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'operator',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
