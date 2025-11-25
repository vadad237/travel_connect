import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  // Get or create chat between two users
  Future<String> getOrCreateChat(
    String userId1,
    String userId2,
    Map<String, dynamic> user1Details,
    Map<String, dynamic> user2Details,
  ) async {
    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in existingChat.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(userId2)) {
          return doc.id;
        }
      }

      // Create new chat
      final chat = ChatModel(
        id: _uuid.v4(),
        participants: [userId1, userId2],
        participantDetails: {
          userId1: user1Details,
          userId2: user2Details,
        },
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: {userId1: 0, userId2: 0},
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('chats').add(chat.toMap());
      return docRef.id;
    } catch (e) {
      print('Error getting or creating chat: $e');
      rethrow;
    }
  }

  // Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get chat messages
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Send message
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    try {
      final message = MessageModel(
        id: _uuid.v4(),
        chatId: chatId,
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
        isRead: false,
        type: 'text',
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}