import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String? id;
  final String ownerId;
  final String name;
  final String country;
  final String city;
  final String address;
  final String phone;
  final String email;
  final DateTime createdAt;

  BusinessModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.country,
    required this.city,
    required this.address,
    required this.phone,
    required this.email,
    required this.createdAt,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime parsedDate;
    if (json['created_at'] is Timestamp) {
      parsedDate = (json['created_at'] as Timestamp).toDate();
    } else if (json['created_at'] != null) {
      parsedDate = DateTime.parse(json['created_at'].toString());
    } else {
      parsedDate = DateTime.now();
    }

    return BusinessModel(
      id: id ?? json['id'],
      ownerId: json['owner_id'] ?? json['ownerId'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'owner_id': ownerId,
      'name': name,
      'country': country,
      'city': city,
      'address': address,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BusinessModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? country,
    String? city,
    String? address,
    String? phone,
    String? email,
    DateTime? createdAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
