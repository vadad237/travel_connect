import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser {
    final user = _auth.currentUser;
    print('🔵 [AuthService] currentUser called: ${user?.uid}');
    return user;
  }
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🔵 [AuthService] Starting Google Sign-In...');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('🔴 [AuthService] User cancelled sign-in');
        return null;
      }

      print('🔵 [AuthService] Got Google account: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔵 [AuthService] Got authentication tokens');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔵 [AuthService] Signing in with Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ [AuthService] Firebase sign-in successful: ${userCredential.user?.uid}');
      
      return userCredential;
    } catch (e, stackTrace) {
      print('🔴 [AuthService] Error signing in: $e');
      print('🔴 [AuthService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Create user document
  Future<void> createUserDocument(User user, String role) async {
    try {
      print('🔵 [AuthService] === Creating user document ===');
      print('🔵 [AuthService] User UID: ${user.uid}');
      print('🔵 [AuthService] User email: ${user.email}');
      print('🔵 [AuthService] Role: "$role"');
      
      final userDoc = _firestore.collection('users').doc(user.uid);
      print('🔵 [AuthService] Document reference: users/${user.uid}');
      
      print('🔵 [AuthService] Checking if document exists...');
      final docSnapshot = await userDoc.get();
      print('🔵 [AuthService] Document exists: ${docSnapshot.exists}');
      
      if (!docSnapshot.exists) {
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL ?? '',
          role: role,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        final dataMap = userModel.toMap();
        print('🔵 [AuthService] Data to write: $dataMap');
        
        print('🔵 [AuthService] Writing document...');
        await userDoc.set(dataMap);
        print('✅ [AuthService] Document written successfully!');
        
        // Verify
        print('🔵 [AuthService] Verifying document was written...');
        final verifyDoc = await userDoc.get();
        print('✅ [AuthService] Verification - exists: ${verifyDoc.exists}, data: ${verifyDoc.data()}');
        
      } else {
        print('🟡 [AuthService] Document already exists, skipping creation');
      }
    } catch (e, stackTrace) {
      print('🔴 [AuthService] ERROR creating document: $e');
      print('🔴 [AuthService] Error type: ${e.runtimeType}');
      print('🔴 [AuthService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      print('🔵 [AuthService] Getting user data for: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      
      print('🔵 [AuthService] Document exists: ${doc.exists}');
      
      if (doc.exists) {
        print('🔵 [AuthService] Document data: ${doc.data()}');
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      
      print('🟡 [AuthService] No document found');
      return null;
    } catch (e, stackTrace) {
      print('🔴 [AuthService] Error getting user data: $e');
      print('🔴 [AuthService] Stack trace: $stackTrace');
      return null;
    }
  }

  // Update user role
  Future<void> updateUserRole(String uid, String role) async {
    try {
      print('🔵 [AuthService] Updating role for $uid to: $role');
      
      final docRef = _firestore.collection('users').doc(uid);
      
      // Check if document exists first
      final doc = await docRef.get();
      
      if (!doc.exists) {
        print('🟡 [AuthService] Document does not exist, creating with role...');
        // Get current user info
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('No authenticated user');
        }
        
        // Create the document with role
        await createUserDocument(user, role);
        return;
      }
      
      // Document exists, update it
      print('🔵 [AuthService] Updating existing document...');
      await docRef.update({
        'role': role,
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      print('✅ [AuthService] Role updated successfully');
    } catch (e, stackTrace) {
      print('🔴 [AuthService] Error updating role: $e');
      print('🔴 [AuthService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🔵 [AuthService] Signing out...');
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('✅ [AuthService] Signed out successfully');
    } catch (e, stackTrace) {
      print('🔴 [AuthService] Error signing out: $e');
      print('🔴 [AuthService] Stack trace: $stackTrace');
      rethrow;
    }
  }
}