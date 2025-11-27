import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create a chat between two users
  Future<String> getOrCreateChat(
    String userId1,
    String userId2,
    Map<String, dynamic> user1Details,
    Map<String, dynamic> user2Details,
  ) async {
    print('🔵 [ChatService] Getting/creating chat between $userId1 and $userId2');

    // Check if chat already exists
    final existingChats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId1)
        .get();

    for (var doc in existingChats.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(userId2)) {
        print('✅ [ChatService] Found existing chat: ${doc.id}');
        return doc.id;
      }
    }

    // Create new chat with unreadCount initialized
    print('🔵 [ChatService] Creating new chat');
    final chatRef = await _firestore.collection('chats').add({
      'participants': [userId1, userId2],
      'participantDetails': {
        userId1: user1Details,
        userId2: user2Details,
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': {
        userId1: 0,
        userId2: 0,
      },
    });

    print('✅ [ChatService] Created new chat: ${chatRef.id}');
    return chatRef.id;
  }

  // Send a message
  Future<void> sendMessage(String chatId, String senderId, String message) async {
    print('🔵 [ChatService] Sending message in chat: $chatId');

    try {
      // Get chat document to find receiver
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
      final receiverId = participants.firstWhere((id) => id != senderId);

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'text',
      });

      // Get current unreadCount
      final currentUnreadCount = chatDoc.data()?['unreadCount'] as Map<String, dynamic>? ?? {};
      final receiverUnreadCount = (currentUnreadCount[receiverId] as num? ?? 0).toInt();

      // Update chat document with last message and increment receiver's unread count
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': receiverUnreadCount + 1,
      });

      print('✅ [ChatService] Message sent, receiver unread count: ${receiverUnreadCount + 1}');
    } catch (e) {
      print('🔴 [ChatService] Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    print('🔵 [ChatService] Marking messages as read for user: $userId in chat: $chatId');

    try {
      final batch = _firestore.batch();

      // Get all unread messages sent to this user
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      print('🔵 [ChatService] Found ${unreadMessages.docs.length} unread messages');

      // Mark all messages as read
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Reset unread count for this user to 0
      batch.update(
        _firestore.collection('chats').doc(chatId),
        {'unreadCount.$userId': 0},
      );

      await batch.commit();
      print('✅ [ChatService] Messages marked as read, unread count reset to 0');
    } catch (e) {
      print('🔴 [ChatService] Error marking messages as read: $e');
    }
  }

  // Get user's chats as stream
  Stream<List<ChatModel>> getUserChats(String userId) {
    print('🔵 [ChatService] Listening to chats for user: $userId');
    
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      print('🔵 [ChatService] Received ${snapshot.docs.length} chats');
      return snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get chat messages as stream
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    print('🔵 [ChatService] Listening to messages in chat: $chatId');
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      print('🔵 [ChatService] Received ${snapshot.docs.length} messages');
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}