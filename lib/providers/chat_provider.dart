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
    print('🔵 [ChatProvider] Listening to chats for user: $userId');
    _chatService.getUserChats(userId).listen((chats) {
      _chats = chats;
      print('🔵 [ChatProvider] Loaded ${chats.length} chats');
      notifyListeners();
    });
  }

  void listenToChatMessages(String chatId) {
    print('🔵 [ChatProvider] Listening to messages for chat: $chatId');
    _chatService.getChatMessages(chatId).listen((messages) {
      _currentChatMessages = messages;
      print('🔵 [ChatProvider] Loaded ${messages.length} messages');
      notifyListeners();
    });
  }

  // Load user chats once (for pull-to-refresh)
  Future<void> loadUserChats(String userId) async {
    print('🔵 [ChatProvider] Loading chats for user: $userId');
    
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

      print('✅ [ChatProvider] Loaded ${_chats.length} chats');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('🔴 [ChatProvider] Error loading chats: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get other user info (name and photo from users, business name from travelAgents if agent)
  Future<Map<String, dynamic>> getOtherUserInfo(String userId) async {
    try {
      print('🔵 [ChatProvider] Getting info for user: $userId');
      
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('🔴 [ChatProvider] User document not found: $userId');
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

      print('🔵 [ChatProvider] User isAgent: $isAgent, photoUrl: ${photoUrl.isNotEmpty ? "present" : "empty"}');

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
            
            print('✅ [ChatProvider] Agent profile - name: $businessName, rating: $averageRating');
            
            return {
              'name': businessName,
              'photoUrl': photoUrl, // Photo from users collection (Google Auth)
              'isAgent': true,
              'averageRating': averageRating,
            };
          } else {
            print('🟡 [ChatProvider] No agent profile found for user: $userId');
          }
        } catch (e) {
          print('🔴 [ChatProvider] Error getting agent profile: $e');
        }
      }

      // For non-agents or if agent profile not found, use user data
      final name = userData['displayName'] as String? ?? 
                   userData['email'] as String? ?? 
                   'Unknown User';

      print('✅ [ChatProvider] User info - name: $name');

      return {
        'name': name,
        'photoUrl': photoUrl, // Photo from users collection (Google Auth)
        'isAgent': false,
        'averageRating': 0.0,
      };
    } catch (e) {
      print('🔴 [ChatProvider] Error getting user info: $e');
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
    print('🔵 [ChatProvider] Getting or creating chat between $userId1 and $userId2');
    
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
      print('✅ [ChatProvider] Chat ID: $chatId');
      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      print('🔴 [ChatProvider] Error creating/getting chat: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    if (text.trim().isEmpty) {
      print('🟡 [ChatProvider] Cannot send empty message');
      return;
    }

    print('🔵 [ChatProvider] Sending message to chat: $chatId');
    try {
      await _chatService.sendMessage(chatId, senderId, text);
      print('✅ [ChatProvider] Message sent successfully');
    } catch (e) {
      print('🔴 [ChatProvider] Error sending message: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    print('🔵 [ChatProvider] Marking messages as read in chat: $chatId');
    try {
      await _chatService.markMessagesAsRead(chatId, userId);
      print('✅ [ChatProvider] Messages marked as read');
    } catch (e) {
      print('🔴 [ChatProvider] Error marking as read: $e');
    }
  }

  void clearCurrentChat() {
    print('🔵 [ChatProvider] Clearing current chat messages');
    _currentChatMessages = [];
    // Schedule notifyListeners for after the current frame to avoid calling it during dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}