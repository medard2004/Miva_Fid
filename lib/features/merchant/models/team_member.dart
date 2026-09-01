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
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'operator',
      isActive: json['is_active'] as bool? ?? (json['isActive'] as bool? ?? true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'is_active': isActive,
  };

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  TeamMember copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
