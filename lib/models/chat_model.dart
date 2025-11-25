import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantDetails;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantDetails,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantDetails: Map<String, dynamic>.from(map['participantDetails'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantDetails': participantDetails,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}