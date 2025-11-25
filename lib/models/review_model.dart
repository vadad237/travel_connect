import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String agentId;
  final String userId;
  final String userName;
  final String userPhoto;
  final double rating;
  final String comment;
  final bool isAnonymous;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.agentId,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.rating,
    required this.comment,
    this.isAnonymous = false,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      agentId: map['agentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agentId': agentId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'comment': comment,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}