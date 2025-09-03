import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF8E24AA); // Purple
  static const Color accentColor = Color(0xFFFF9800);   // Orange
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color errorColor = Color(0xFFCF6679);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);
}

class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String busesCollection = 'buses';
  static const String commentsCollection = 'comments';
  static const String attendanceCollection = 'attendance';
  static const String notificationsCollection = 'notifications';
  
  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userLoggedInKey = 'user_logged_in';
  
  // Secure Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  
  // API Keys
  static const String googleMapsApiKey = 'AIzaSyAiMIS2-SZX2vOeRrWWgsXawkDRvp4FtbE';
}