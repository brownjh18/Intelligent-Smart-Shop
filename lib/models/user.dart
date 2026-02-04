import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final String language;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    required this.language,
    required this.createdAt,
  });

  factory UserModel.fromAuth(auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      language: 'en',
      createdAt: DateTime.now(),
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      language: data['language'] ?? 'en',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'language': language,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? profileImageUrl,
    String? language,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      language: language ?? this.language,
      createdAt: createdAt,
    );
  }
}
