import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String role; // 'user' or 'agent'
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastActive: (map['lastActive'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }
}