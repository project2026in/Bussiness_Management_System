class UserModel {
  final String password;
  final String name;
  final String phone;
  final String email;
  final DateTime? dob;

  UserModel({
    required this.password,
    required this.name,
    required this.phone,
    required this.email,
    this.dob,
  });

  // From JSON (e.g. API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      password: json['password'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
    );
  }

  // To JSON (e.g. sending to API)
  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'name': name,
      'phone': phone,
      'email': email,
      'dob': dob?.toIso8601String(),
    };
  }

  // Optional: copyWith for immutable updates
  UserModel copyWith({
    String? password,
    String? name,
    String? phone,
    String? email,
    DateTime? dob,
  }) {
    return UserModel(
      password: password ?? this.password,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
    );
  }
}
