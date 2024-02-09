import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _personToContactController = TextEditingController();
  final _contactPersonPhoneController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String role = "regular"; // Default user role

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _dateOfBirthController.dispose();
    _homeAddressController.dispose();
    _personToContactController.dispose();
    _contactPersonPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate() && _profileImage != null) {
      UserService userService = UserService();
      String? imageUrl = await userService.uploadImageToStorage(
          _profileImage!, _emailController.text);

      await userService.registerUser(
        _emailController.text,
        _passwordController.text,
        _fullNameController.text,
        _phoneNumberController.text,
        _dateOfBirthController.text,
        _homeAddressController.text,
        _personToContactController.text,
        _contactPersonPhoneController.text,
        _profileImage!, // Passing the profile image file
        imageUrl ?? '', // Passing imageUrl as a String
        role, // Passing role
      );
      // Handle navigation or success message here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Register",
          style: GoogleFonts.nunito(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_profileImage != null)
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: FileImage(_profileImage!),
                  ),
                TextButton(
                  onPressed: _pickImage,
                  child: Text('Select Profile Image'),
                ),
                _buildTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name',
                  icon: Icons.person,
                ),
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                  suffixIcon: Icons.visibility_off, // Toggle visibility icon
                ),
                DropdownButtonFormField<String>(
                  value: role,
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  onChanged: (String? newValue) {
                    setState(() {
                      role = newValue!;
                    });
                  },
                  items: <String>[
                    'regular',
                    'admin',
                    'police',
                    'fire',
                    'medical',
                    'traffic'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),

                _buildTextField(
                  controller: _phoneNumberController,
                  labelText: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  controller: _dateOfBirthController,
                  labelText: 'Date of Birth',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.datetime,
                ),
                _buildTextField(
                  controller: _homeAddressController,
                  labelText: 'Home Address',
                  icon: Icons.home,
                ),
                _buildTextField(
                  controller: _personToContactController,
                  labelText: 'Person to Contact',
                  icon: Icons.person_search,
                ),
                _buildTextField(
                  controller: _contactPersonPhoneController,
                  labelText: 'Contact Person\'s Phone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 20),
                // Add other fields as needed...
                ElevatedButton(
                  onPressed: _registerUser,
                  child: Text(
                    'Register',
                    style: GoogleFonts.nunito(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    textStyle: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $labelText';
          }
          return null;
        },
      ),
    );
  }
}

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref().child('Users');
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
    File profileImage,
    String imageUrl,
    String role, // Change userType to role
  ) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Save user information in the database along with the image URL and role
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
          'role': role, // Store the role
        });

        print("User registration successful");
      }
    } catch (e) {
      print("Error registering user: $e");
    }
  }
}
