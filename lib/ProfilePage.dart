import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('Users');
  Map userData = {};

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (user != null) {
      DataSnapshot snapshot = await _userRef.child(user!.uid).get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.value as Map;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey, // Custom color for AppBar
        elevation: 4.0,
      ),
      body: userData.isNotEmpty
          ? _buildProfileView()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildProfileView() {
    return ListView(
      padding: EdgeInsets.all(16), // Padding around the list
      children: <Widget>[
        _buildAvatar(),
        SizedBox(height: 24), // Space between avatar and information
        _buildInfoSection(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Center(
        child: CircleAvatar(
      radius: 60, // Size of the avatar
      backgroundImage: NetworkImage(userData['profileImageUrl']),
      backgroundColor: Colors.grey.shade300,
    ));
  }

  Widget _buildInfoSection() {
    return Column(
      children: <Widget>[
        _infoTile('Name', userData['name'] ?? ''),
        _infoTile('Email', userData['email'] ?? ''),
        _infoTile('Phone', userData['phoneNumber'] ?? ''),
        _infoTile('Date of Birth', userData['dateOfBirth'] ?? ''),
        _infoTile('Home Address', userData['homeAddress'] ?? ''),
        _infoTile('Emergency Contact', userData['personToContact'] ?? ''),
        _infoTile(
            'Emergency Contact Phone', userData['contactPersonPhone'] ?? ''),
      ],
    );
  }

  Widget _infoTile(String title, String subtitle) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
