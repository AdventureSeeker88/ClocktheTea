import 'package:clock_tea/Auth/LoginScreen.dart';
import 'package:clock_tea/Auth/ProfileSetup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../MainScreen.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Rxn<User> firebaseUser = Rxn<User>();
  RxBool isLoading = false.obs;

  // ✅ REGISTER NEW USER
  Future<void> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Return control to profile setup screen
      Get.snackbar(
        'Registration Successful',
        'Proceed to complete your profile setup.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.greenAccent,
        colorText: Colors.black,
      );

      Get.offAll(() => ProfileSetupScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Registration Failed',
        e.message ?? 'Unknown error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ LOGIN
  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar(
        'Login Successful',
        'Welcome back!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.greenAccent,
        colorText: Colors.black,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Failed',
        e.message ?? 'Unknown error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Google Sign-In
  /// ---------------------------
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return; // User cancelled login

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 🔐 Sign in with Firebase
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final uid = userCredential.user!.uid;

      // 🔍 Check if user exists in Firestore
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();

      // ✅ If user is new — go to profile setup
      if (!userDoc.exists) {
        Get.offAll(() => ProfileSetupScreen());
      } else {
        // ✅ If user already exists — go to main/home screen
        Get.offAll(() => MainShell());
      }

      Get.snackbar(
        "Success",
        "Logged in with Google!",
        backgroundColor: Colors.greenAccent,
        colorText: Colors.black,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Google Sign-In failed");
      print(e.message ?? "Google Sign-In failed");
    } catch (e) {
      Get.snackbar("Error", "Google Sign-In failed: $e");
      print("Google Sign-In error: $e");
    }
  }


  // ✅ LOGOUT
  Future<void> logoutUser() async {
    try {
      // ✅ Sign out from Firebase
      await _auth.signOut();

      // ✅ Also sign out from Google if user used Google Sign-In
      try {

        final GoogleSignIn _googleSignIn = GoogleSignIn();
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (e) {
        // ignore if user wasn’t signed in with Google
      }

      // ✅ Show confirmation
      Get.snackbar(
        'Logged Out',
        'You have been signed out successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      // ✅ Redirect to Login Screen
      Get.offAll(() => LoginScreen());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Logout failed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
