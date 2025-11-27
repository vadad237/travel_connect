import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  
  bool get isAuthenticated {
    final firebaseUser = _authService.currentUser;
    return firebaseUser != null;
  }

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if user is already signed in
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _isLoading = true;
      notifyListeners();
      
      await _loadUserData(firebaseUser.uid);
      
      _isLoading = false;
      notifyListeners();
    }
    
    // Start listening to auth changes
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Don't reload if we already have this user's data
        if (_currentUser?.id != firebaseUser.uid) {
          await _loadUserData(firebaseUser.uid);
        }
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _currentUser = await _authService.getUserData(uid);
      
      if (_currentUser == null) {
        // Get Firebase user
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          // Create document
          await _authService.createUserDocument(firebaseUser, '');
          
          // Try loading again
          _currentUser = await _authService.getUserData(uid);
          
          if (_currentUser == null) {
            // Create temporary model
            _currentUser = UserModel(
              id: uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName ?? '',
              photoUrl: firebaseUser.photoURL ?? '',
              role: '',
              createdAt: DateTime.now(),
              lastActive: DateTime.now(),
            );
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Create user document with empty role
      try {
        await _authService.createUserDocument(userCredential.user!, '');
      } catch (createError) {
        // Silently handle error
      }
      
      // Load user data
      _currentUser = await _authService.getUserData(userCredential.user!.uid);
      
      if (_currentUser == null) {
        _currentUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? '',
          photoUrl: userCredential.user!.photoURL ?? '',
          role: '',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setUserRole(String role) async {
    if (_authService.currentUser != null) {
      final uid = _authService.currentUser!.uid;
      
      try {
        final userData = await _authService.getUserData(uid);
        
        if (userData == null) {
          await _authService.createUserDocument(_authService.currentUser!, role);
        } else {
          await _authService.updateUserRole(uid, role);
        }
        
        await _loadUserData(uid);
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.signOut();
      _currentUser = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshUserData() async {
    if (_authService.currentUser != null) {
      await _loadUserData(_authService.currentUser!.uid);
    }
  }
}