import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String type;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.type = 'text',
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle timestamp - it can be null, Timestamp, or already DateTime
    DateTime messageTimestamp;
    final timestampField = map['timestamp'];
    
    if (timestampField == null) {
      // If null (pending server timestamp), use current time
      messageTimestamp = DateTime.now();
    } else if (timestampField is Timestamp) {
      messageTimestamp = timestampField.toDate();
    } else if (timestampField is DateTime) {
      messageTimestamp = timestampField;
    } else {
      // Fallback
      messageTimestamp = DateTime.now();
    }

    return MessageModel(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['message'] as String? ?? map['text'] as String? ?? '',
      timestamp: messageTimestamp,
      isRead: map['isRead'] as bool? ?? false,
      type: map['type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type,
    };
  }
}