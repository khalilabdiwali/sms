import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms/RegistrationScreen.dart';
import 'package:sms/SignUpPage.dart';
import 'package:sms/home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        await _auth.signInWithEmailAndPassword(
            email: _email, password: _password);

        // Navigate to the home page after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => home()),
        );
      } catch (e) {
        print(e); // Handle errors here
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlutterLogo(size: 100),
                SizedBox(height: 50),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _email = value),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter an email' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onChanged: (value) => setState(() => _password = value),
                  validator: (value) => value!.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Login',
                          style: GoogleFonts.nunito(fontSize: 20),
                        ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // full width button
                  ),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegistrationScreen()));
                    },
                    child: Text(
                      'SignUp',
                      style: GoogleFonts.nunito(fontSize: 17),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Welcome!')),
    );
  }
}
