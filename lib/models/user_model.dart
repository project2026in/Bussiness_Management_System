import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String password;
  final String name;
  final String phone;
  final String email;
  final DateTime? dob;
  final String role;
  final String? ownerId;
  final String? businessId;
  final String? salary;
  final String? ip;
  final String? location;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    this.id,
    required this.password,
    required this.name,
    required this.phone,
    required this.email,
    this.dob,
    this.role = 'Owner',
    this.ownerId,
    this.businessId,
    this.salary,
    this.ip,
    this.location,
    this.isActive = true,
    this.createdAt,
  });

  // From JSON (e.g. API response)
  factory UserModel.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null || json['created_at'] != null) {
      final dateVal = json['createdAt'] ?? json['created_at'];
      if (dateVal is Timestamp) {
        parsedCreatedAt = dateVal.toDate();
      } else {
        parsedCreatedAt = DateTime.tryParse(dateVal.toString());
      }
    }

    return UserModel(
      id: id ?? json['id'],
      password: json['password'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      role: json['role'] ?? 'Owner',
      ownerId: json['owner_id'] ?? json['ownerId'],
      businessId: json['business_id'] ?? json['businessId'],
      salary: json['salary'],
      ip: json['ip'],
      location: json['location'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  // To JSON (e.g. sending to API)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'password': password,
      'name': name,
      'phone': phone,
      'email': email,
      if (dob != null) 'dob': dob?.toIso8601String(),
      'role': role,
      if (ownerId != null) 'owner_id': ownerId,
      if (businessId != null) 'business_id': businessId,
      if (salary != null) 'salary': salary,
      if (ip != null) 'ip': ip,
      if (location != null) 'location': location,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  // Optional: copyWith for immutable updates
  UserModel copyWith({
    String? id,
    String? password,
    String? name,
    String? phone,
    String? email,
    DateTime? dob,
    String? role,
    String? ownerId,
    String? businessId,
    String? salary,
    String? ip,
    String? location,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      password: password ?? this.password,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      role: role ?? this.role,
      ownerId: ownerId ?? this.ownerId,
      businessId: businessId ?? this.businessId,
      salary: salary ?? this.salary,
      ip: ip ?? this.ip,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
