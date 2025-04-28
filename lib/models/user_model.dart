import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String role;
  final bool isVerified;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.role = 'user',
    this.isVerified = false,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      role: data['role'] ?? 'user',
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt']?.toDate(),
    );
  }
}
