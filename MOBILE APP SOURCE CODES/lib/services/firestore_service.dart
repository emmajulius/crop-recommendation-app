import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No logged-in user found.');
        return null;
      }

      final doc = await _db.collection('users').doc(user.uid).get();

      if (doc.exists) {
        print('User data fetched successfully: ${doc.data()}');
        return doc.data();
      } else {
        print('User document does not exist in Firestore.');
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No logged-in user found.');
      }

      await _db.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
      print('User data updated successfully.');
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> deleteUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No logged-in user found.');
      }

      await _db.collection('users').doc(user.uid).delete();
      print('User data deleted successfully.');
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}
