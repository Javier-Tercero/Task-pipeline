import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The signed-in user's data root, `users/{uid}`.
///
/// Every project and task lives under it, so ownership is enforced by the path
/// itself (see firestore.rules) instead of by a field that has to be checked.
DocumentReference<Map<String, dynamic>> currentUserRoot() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('No signed-in user.');
  return FirebaseFirestore.instance.collection('users').doc(user.uid);
}
