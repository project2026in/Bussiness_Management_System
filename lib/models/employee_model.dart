import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeModel {
  final String? id;
  final String ownerId;
  final String businessId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String salary;
  final String ip;
  final String location;
  final bool isActive;
  final DateTime createdAt;

  EmployeeModel({
    this.id,
    required this.ownerId,
    required this.businessId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.salary,
    required this.ip,
    required this.location,
    this.isActive = true,
    required this.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime parsedDate;
    if (json['created_at'] is Timestamp) {
      parsedDate = (json['created_at'] as Timestamp).toDate();
    } else if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return EmployeeModel(
      id: id ?? json['id'],
      ownerId: json['owner_id'] ?? '',
      businessId: json['business_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'Employee',
      salary: json['salary'] ?? '',
      ip: json['ip'] ?? 'Unknown',
      location: json['location'] ?? 'Unknown',
      isActive: json['is_active'] ?? true,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'owner_id': ownerId,
      'business_id': businessId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'salary': salary,
      'ip': ip,
      'location': location,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? ownerId,
    String? businessId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? salary,
    String? ip,
    String? location,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      ip: ip ?? this.ip,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
