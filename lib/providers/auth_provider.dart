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
    print('🔵 [AuthProvider] isAuthenticated check: firebaseUser=${firebaseUser?.uid}, currentUser=${_currentUser?.id}');
    return firebaseUser != null;
  }

  AuthProvider() {
    print('🔵 [AuthProvider] Constructor called');
    _initialize();
  }

  Future<void> _initialize() async {
    print('🔵 [AuthProvider] Initializing...');
    
    // Check if user is already signed in
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      print('🔵 [AuthProvider] Found existing user: ${firebaseUser.uid}');
      _isLoading = true;
      notifyListeners();
      
      await _loadUserData(firebaseUser.uid);
      
      _isLoading = false;
      notifyListeners();
    } else {
      print('🔵 [AuthProvider] No existing user');
    }
    
    // Start listening to auth changes
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    print('🔵 [AuthProvider] Setting up auth listener');
    
    _authService.authStateChanges.listen((User? firebaseUser) async {
      print('🔵 [AuthProvider] Auth state changed: ${firebaseUser?.uid}');
      
      if (firebaseUser != null) {
        print('🔵 [AuthProvider] User signed in, loading data...');
        
        // Don't reload if we already have this user's data
        if (_currentUser?.id != firebaseUser.uid) {
          await _loadUserData(firebaseUser.uid);
        } else {
          print('🟡 [AuthProvider] Already have data for this user');
        }
      } else {
        print('🔵 [AuthProvider] User signed out');
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    print('🔵 [AuthProvider] Loading user data for: $uid');
    
    try {
      _currentUser = await _authService.getUserData(uid);
      
      if (_currentUser == null) {
        print('🟡 [AuthProvider] No user document found, creating one...');
        
        // Get Firebase user
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          // Create document
          await _authService.createUserDocument(firebaseUser, '');
          
          // Try loading again
          _currentUser = await _authService.getUserData(uid);
          
          if (_currentUser == null) {
            print('🔴 [AuthProvider] Still no user data, creating temporary model');
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
      } else {
        print('✅ [AuthProvider] User loaded: ${_currentUser?.email}, role: "${_currentUser?.role}"');
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      print('🔴 [AuthProvider] Error loading user data: $e');
      print('🔴 [AuthProvider] Stack: $stackTrace');
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔵 [AuthProvider] Starting sign-in...');
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential == null) {
        print('🔴 [AuthProvider] Sign-in cancelled');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('🔵 [AuthProvider] Sign-in successful: ${userCredential.user?.uid}');
      
      // Create user document with empty role
      print('🔵 [AuthProvider] Creating user document...');
      try {
        await _authService.createUserDocument(userCredential.user!, '');
        print('✅ [AuthProvider] Document creation completed');
      } catch (createError) {
        print('🔴 [AuthProvider] Document creation FAILED: $createError');
      }
      
      // Load user data
      print('🔵 [AuthProvider] Loading user data...');
      _currentUser = await _authService.getUserData(userCredential.user!.uid);
      
      if (_currentUser == null) {
        print('🟡 [AuthProvider] No user data found, creating temporary model');
        _currentUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? '',
          photoUrl: userCredential.user!.photoURL ?? '',
          role: '',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
      } else {
        print('✅ [AuthProvider] User loaded: ${_currentUser?.email}, role: "${_currentUser?.role}"');
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('🔴 [AuthProvider] Error: $e');
      print('🔴 [AuthProvider] Stack: $stackTrace');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setUserRole(String role) async {
    if (_authService.currentUser != null) {
      print('🔵 [AuthProvider] Setting role to: $role');
      
      final uid = _authService.currentUser!.uid;
      
      try {
        final userData = await _authService.getUserData(uid);
        
        if (userData == null) {
          print('🟡 [AuthProvider] Document not found, creating with role...');
          await _authService.createUserDocument(_authService.currentUser!, role);
        } else {
          print('🔵 [AuthProvider] Document exists, updating role...');
          await _authService.updateUserRole(uid, role);
        }
        
        print('🔵 [AuthProvider] Reloading user data...');
        await _loadUserData(uid);
        print('✅ [AuthProvider] Role set successfully');
        
      } catch (e, stackTrace) {
        print('🔴 [AuthProvider] Error setting role: $e');
        print('🔴 [AuthProvider] Stack: $stackTrace');
        rethrow;
      }
    } else {
      print('🔴 [AuthProvider] Cannot set role: No authenticated user');
    }
  }

  Future<void> signOut() async {
    try {
      print('🔵 [AuthProvider] Signing out...');
      await _authService.signOut();
      _currentUser = null;
      print('✅ [AuthProvider] Signed out successfully');
      notifyListeners();
    } catch (e) {
      print('🔴 [AuthProvider] Error signing out: $e');
      rethrow;
    }
  }

  Future<void> refreshUserData() async {
    if (_authService.currentUser != null) {
      print('🔵 [AuthProvider] Refreshing user data...');
      await _loadUserData(_authService.currentUser!.uid);
    } else {
      print('🟡 [AuthProvider] Cannot refresh: No authenticated user');
    }
  }
}