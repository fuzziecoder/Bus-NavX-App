import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _auth.currentUser != null;

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      
      if (user != null) {
        // Save user session locally
        await _saveUserSession(user.uid);
        
        // Get user data from Firestore (to be implemented in FirestoreService)
        // _currentUser = await _firestoreService.getUserData(user.uid);
        
        _isLoading = false;
        notifyListeners();
        return _currentUser;
      }
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.sendPasswordResetEmail(email: email);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearUserSession();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool(AppConstants.userLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        final String? userId = prefs.getString(AppConstants.userIdKey);
        if (userId != null) {
          // Get user data from Firestore (to be implemented in FirestoreService)
          // _currentUser = await _firestoreService.getUserData(userId);
          notifyListeners();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Save user session locally
  Future<void> _saveUserSession(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.userLoggedInKey, true);
      await prefs.setString(AppConstants.userIdKey, userId);
      
      // Save auth token in secure storage
      final String? token = await _auth.currentUser?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: AppConstants.tokenKey, value: token);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Clear user session
  Future<void> _clearUserSession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userLoggedInKey);
      await prefs.remove(AppConstants.userIdKey);
      
      // Remove auth token from secure storage
      await _secureStorage.delete(key: AppConstants.tokenKey);
      await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    } catch (e) {
      rethrow;
    }
  }
}