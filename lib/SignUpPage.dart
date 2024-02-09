import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms/ProfilePage.dart';
import 'package:sms/RegistrationScreen.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _userType = 'user'; // Default to 'user'

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // Store user type in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'userType': _userType,
        });

        // Navigate to the appropriate screen based on user type
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  _userType == 'user' ? UserHomePage() : AdminHomePage()),
        );
      } catch (e) {
        print(e); // Handle errors here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FlutterLogo(size: 100),
                  SizedBox(height: 48),
                  Text(
                    'Create Account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    onChanged: (value) => setState(() => _email = value),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter an email' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    onChanged: (value) => setState(() => _password = value),
                    validator: (value) => value!.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'User Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _userType,
                    onChanged: (String? newValue) {
                      setState(() {
                        _userType = newValue!;
                      });
                    },
                    items: <String>['user', 'admin']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _signUp,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Sign Up', style: TextStyle(fontSize: 16)),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(double.infinity, 50), // full width
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfilePage()));
                      },
                      child: Text(
                        'Profile Page',
                        style: GoogleFonts.nunito(fontSize: 17),
                      ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Home')),
      body: Center(child: Text('Welcome User')),
    );
  }
}

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Home')),
      body: Center(child: Text('Welcome Admin')),
    );
  }
}
