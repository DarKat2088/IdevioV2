import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addIdea(String userId, String text) async {
    await _db.collection('ideas').add({
      'userId': userId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getIdeas() {
    return _db.collection('ideas').orderBy('createdAt', descending: true).snapshots();
  }
}