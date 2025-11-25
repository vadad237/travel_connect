import 'package:cloud_firestore/cloud_firestore.dart';

class TravelAgentModel {
  final String id;
  final String userId;
  final String businessName;
  final String description;
  final String profilePhoto;
  final String location;
  final List<String> specializations;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;

  TravelAgentModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    required this.profilePhoto,
    required this.location,
    this.specializations = const [],
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'description': description,
      'profilePhoto': profilePhoto,
      'location': location,
      'specializations': specializations,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': createdAt,
    };
  }

  factory TravelAgentModel.fromMap(Map<String, dynamic> map, String id) {
    return TravelAgentModel(
      id: id,
      userId: map['userId'] ?? '',
      businessName: map['businessName'] ?? '',
      description: map['description'] ?? '',
      profilePhoto: map['profilePhoto'] ?? '',
      location: map['location'] ?? '',
      specializations: map['specializations'] != null
          ? List<String>.from(map['specializations'])
          : [],
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as int?) ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}