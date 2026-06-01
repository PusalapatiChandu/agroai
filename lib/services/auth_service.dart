// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/detection_result.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email & password
  Future<UserCredential?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String location,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      // Save farmer profile
      await _db.collection('farmers').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'farmSize': '',
        'mainCrops': [],
        'totalScans': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<UserCredential?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      notifyListeners();
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Fetch farmer profile
  Future<FarmerProfile?> fetchProfile() async {
    if (currentUser == null) return null;
    final doc = await _db.collection('farmers').doc(currentUser!.uid).get();
    if (!doc.exists) return null;
    return FarmerProfile.fromMap(doc.data()!);
  }

  // Update profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await _db.collection('farmers').doc(currentUser!.uid).update(data);
    notifyListeners();
  }
}
