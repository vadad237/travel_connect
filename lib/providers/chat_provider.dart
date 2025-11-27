import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ChatModel> _chats = [];
  List<MessageModel> _currentChatMessages = [];
  bool _isLoading = false;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get currentChatMessages => _currentChatMessages;
  bool get isLoading => _isLoading;

  void listenToUserChats(String userId) {
    _chatService.getUserChats(userId).listen((chats) {
      _chats = chats;
      notifyListeners();
    });
  }

  void listenToChatMessages(String chatId) {
    _chatService.getChatMessages(chatId).listen((messages) {
      _currentChatMessages = messages;
      notifyListeners();
    });
  }

  // Load user chats once (for pull-to-refresh)
  Future<void> loadUserChats(String userId) async {
    // Set loading state safely
    if (_isLoading != true) {
      _isLoading = true;
      // Schedule notifyListeners for after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      _chats = querySnapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get other user info (name and photo from users, business name from travelAgents if agent)
  Future<Map<String, dynamic>> getOtherUserInfo(String userId) async {
    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return {
          'name': 'Unknown User',
          'photoUrl': '',
          'isAgent': false,
          'averageRating': 0.0,
        };
      }

      final userData = userDoc.data()!;
      final role = userData['role'] as String? ?? '';
      final isAgent = role == 'agent';
      
      // Always get photo from users collection (Google Auth photo)
      final photoUrl = userData['photoUrl'] as String? ?? '';

      // If agent, get their business name from travelAgents collection
      if (isAgent) {
        try {
          final agentQuery = await _firestore
              .collection('travelAgents')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (agentQuery.docs.isNotEmpty) {
            final agentData = agentQuery.docs.first.data();
            final businessName = agentData['businessName'] as String? ?? 'Travel Agent';
            final averageRating = (agentData['averageRating'] as num?)?.toDouble() ?? 0.0;
            
            return {
              'name': businessName,
              'photoUrl': photoUrl, // Photo from users collection (Google Auth)
              'isAgent': true,
              'averageRating': averageRating,
            };
          }
        } catch (e) {
          // Silently handle error
        }
      }

      // For non-agents or if agent profile not found, use user data
      final name = userData['displayName'] as String? ?? 
                   userData['email'] as String? ?? 
                   'Unknown User';

      return {
        'name': name,
        'photoUrl': photoUrl, // Photo from users collection (Google Auth)
        'isAgent': false,
        'averageRating': 0.0,
      };
    } catch (e) {
      return {
        'name': 'Unknown User',
        'photoUrl': '',
        'isAgent': false,
        'averageRating': 0.0,
      };
    }
  }

  Future<String> getOrCreateChat(
    String userId1,
    String userId2,
    Map<String, dynamic> user1Details,
    Map<String, dynamic> user2Details,
  ) async {
    // Set loading state safely
    if (_isLoading != true) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final chatId = await _chatService.getOrCreateChat(
        userId1,
        userId2,
        user1Details,
        user2Details,
      );
      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _chatService.sendMessage(chatId, senderId, text);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatId, userId);
    } catch (e) {
      // Silently handle error
    }
  }

  void clearCurrentChat() {
    _currentChatMessages = [];
    // Schedule notifyListeners for after the current frame to avoid calling it during dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}