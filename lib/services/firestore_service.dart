import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../models/bus_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User methods
  Future<UserModel?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Bus methods
  Future<BusModel?> getBusData(String busNo) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.busesCollection)
          .where('busNo', isEqualTo: busNo)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BusModel.fromJson(
            snapshot.docs.first.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BusModel>> getAllBuses() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection(AppConstants.busesCollection).get();

      return snapshot.docs
          .map((doc) => BusModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Comment methods
  Future<void> addComment(CommentModel comment) async {
    try {
      await _firestore
          .collection(AppConstants.commentsCollection)
          .add(comment.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CommentModel>> getCommentsByBus(String busNo) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.commentsCollection)
          .where('busNo', isEqualTo: busNo)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              CommentModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Attendance methods
  Future<void> logAttendance(String userId, String busNo) async {
    try {
      await _firestore.collection(AppConstants.attendanceCollection).add({
        'userId': userId,
        'busNo': busNo,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Notification methods
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromJson(
              (doc.data() as Map<String, dynamic>)..['id'] = doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }
}