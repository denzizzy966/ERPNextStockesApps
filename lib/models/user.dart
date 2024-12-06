class User {
  final String username;
  final String lastLogin;
  final String ipAddress;
  
  // Additional fields from API
  final String? name;
  final String? email;
  final String? firstName;
  final String? fullName;
  final String? language;
  final String? timeZone;
  final String? userType;
  final String? lastActive;
  final String? lastIp;
  final List<UserRole>? roles;

  User({
    required this.username,
    required this.lastLogin,
    required this.ipAddress,
    this.name,
    this.email,
    this.firstName,
    this.fullName,
    this.language,
    this.timeZone,
    this.userType,
    this.lastActive,
    this.lastIp,
    this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      lastLogin: json['last_login'] ?? '',
      ipAddress: json['last_ip'] ?? '',
      name: json['name'],
      email: json['email'],
      firstName: json['first_name'],
      fullName: json['full_name'],
      language: json['language'],
      timeZone: json['time_zone'],
      userType: json['user_type'],
      lastActive: json['last_active'],
      lastIp: json['last_ip'],
      roles: (json['roles'] as List<dynamic>?)
          ?.map((role) => UserRole.fromJson(role))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'last_login': lastLogin,
      'last_ip': ipAddress,
      'name': name,
      'email': email,
      'first_name': firstName,
      'full_name': fullName,
      'language': language,
      'time_zone': timeZone,
      'user_type': userType,
      'last_active': lastActive,
      'roles': roles?.map((role) => role.toJson()).toList(),
    };
  }
}

class UserRole {
  final String name;
  final String role;
  final String parent;
  final String parentfield;
  final String parenttype;
  final String doctype;

  UserRole({
    required this.name,
    required this.role,
    required this.parent,
    required this.parentfield,
    required this.parenttype,
    required this.doctype,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      parent: json['parent'] ?? '',
      parentfield: json['parentfield'] ?? '',
      parenttype: json['parenttype'] ?? '',
      doctype: json['doctype'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'parent': parent,
      'parentfield': parentfield,
      'parenttype': parenttype,
      'doctype': doctype,
    };
  }
}
