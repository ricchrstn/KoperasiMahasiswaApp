import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data
  Future<UserModel> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return UserModel.fromFirestore(doc);
  }

  // Verify user
  Future<void> verifyUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all unverified users
  Stream<List<UserModel>> getUnverifiedUsers() {
    return _firestore
        .collection('users')
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  
}