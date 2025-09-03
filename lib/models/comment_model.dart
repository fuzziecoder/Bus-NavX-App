import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImage;
  final String busNo;
  final String text;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String type; // 'text', 'image', 'issue'

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.busNo,
    required this.text,
    required this.imageUrls,
    required this.createdAt,
    required this.type,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      busNo: json['busNo'] ?? '',
      text: json['text'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: json['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'busNo': busNo,
      'text': text,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'type': type,
    };
  }
}