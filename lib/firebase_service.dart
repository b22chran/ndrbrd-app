import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser(String name, int age) async {
    await _db.collection('users').add({
      'name': name,
      'age': age,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

Stream<QuerySnapshot> getUsers() {
  return FirebaseFirestore.instance.collection('testDB').snapshots();
}