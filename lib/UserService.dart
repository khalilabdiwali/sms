import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('Users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImageToStorage(File imageFile, String userId) async {
    try {
      final storageRef = _storage.ref('user_images/$userId.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      await uploadTask.whenComplete(() => null);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> registerUser(
    String email,
    String password,
    String fullName,
    String phoneNumber,
    String dateOfBirth,
    String homeAddress,
    String personToContact,
    String contactPersonPhone,
    File profileImage,  // Include the profile image file
  ) async {
    try {
      // Authenticate the user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Upload the image to Firebase Storage
        String? imageUrl = await uploadImageToStorage(profileImage, user.uid);

        // Save user information in the database along with the image URL
        await _userRef.child(user.uid).set({
          'uid': user.uid,
          'name': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'dateOfBirth': dateOfBirth,
          'homeAddress': homeAddress,
          'personToContact': personToContact,
          'contactPersonPhone': contactPersonPhone,
          'profileImageUrl': imageUrl, // Store the image URL
        });

        // User registration successful
        print("User registration successful");
      }
    } catch (e) {
      // Handle errors
      print("Error registering user: $e");
    }
  }
}
