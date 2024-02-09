import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sms/ChatScreen.dart';
import 'package:sms/LoginPage.dart';
import 'package:sms/ProfilePage.dart';
import 'package:sms/gpd.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

bool _iconBool = false;
IconData _iconLight = Icons.wb_sunny;
IconData _iconDark = Icons.nights_stay;
ThemeData _lightTheme = ThemeData(
  primarySwatch: Colors.amber,
  brightness: Brightness.light,
);

ThemeData _darkTheme = ThemeData(
  primarySwatch: Colors.red,
  brightness: Brightness.dark,
);
int _currentIndex = 0;

class home extends StatefulWidget {
  const home({super.key});
  @override
  State<home> createState() => _homeState();
}

final FirebaseAuth _auth = FirebaseAuth.instance;
void _logout(BuildContext context) async {
  await _auth.signOut();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
        builder: (context) => LoginPage()), // Navigate back to the login page
  );
}

class _homeState extends State<home> {
  final List<Widget> _pages = [HomePage(), ProfilePage(), Hello()];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: _iconBool ? _darkTheme : _lightTheme,
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.indigo,
            title: Text(
              'Emergency  App',
              style: GoogleFonts.nunito(
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () => _logout(context),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _iconBool = !_iconBool;
                  });
                },
                icon: Icon(_iconBool ? _iconDark : _iconLight),
              )
            ],
            centerTitle: true,
            iconTheme: IconThemeData(
              size: 30,
              color: Colors.white,
            ),
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                FutureBuilder<DataSnapshot>(
                  future: FirebaseDatabase.instance
                      .ref('Users/${FirebaseAuth.instance.currentUser?.uid}')
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DataSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // Show loading indicator while waiting for data
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      // Default values
                      String userName = 'No Name';
                      String profileImageUrl =
                          'https://via.placeholder.com/150'; // Placeholder image URL

                      if (snapshot.hasData && snapshot.data?.value != null) {
                        var userData =
                            snapshot.data!.value as Map<dynamic, dynamic>;
                        userName = userData['name'] ?? 'No Name';
                        profileImageUrl = userData['profileImageUrl'] ??
                            'https://via.placeholder.com/150'; // Use a default or placeholder image URL if not available
                      }

                      return UserAccountsDrawerHeader(
                        accountName: Text(userName),
                        currentAccountPicture: CircleAvatar(
                          backgroundImage: NetworkImage(profileImageUrl),
                          child: Text(userName.isNotEmpty
                              ? userName[0]
                              : 'U'), // First letter of the user's name
                        ),
                        accountEmail:
                            null, // Assuming no email is to be displayed, set to null
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text(
                    'Settings',
                    style: GoogleFonts.nunito(),
                  ),
                  onTap: () {
                    // Close the drawer
                    // Navigator.pop(context);

                    // Navigate to the Settings page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.dark_mode),
                  title: Text(
                    'Dark Mode',
                    style: GoogleFonts.nunito(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.policy),
                  title: Text(
                    'Policy',
                    style: GoogleFonts.nunito(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.language,
                  ),
                  title: Text(
                    'Languages',
                    style: GoogleFonts.nunito(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_rounded),
                  title: Text(
                    'About',
                    style: GoogleFonts.nunito(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pages[_currentIndex],
                  ]),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.gps_off),
                label: 'Maps',
              ),
            ],
          ),
        ));
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          ListTile(
            title: Text('Notifications'),
            trailing: Switch(
              value: true, // Example switch value
              onChanged: (bool value) {
                // Handle switch state change
              },
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (bool value) {
                // Toggle dark mode
                ThemeMode newThemeMode =
                    value ? ThemeMode.dark : ThemeMode.light;
                _changeTheme(context, newThemeMode);
              },
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Change Password'),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              // Handle password change
            },
          ),
          Divider(),
          ListTile(
            title: Text('Languages'),
            trailing: Icon(Icons.language),
            onTap: () {
              // Navigate to language selection page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Logout'),
            trailing: Icon(Icons.exit_to_app),
            onTap: () {
              // Handle logout
            },
          ),
        ],
      ),
    );
  }

  void _changeTheme(BuildContext context, ThemeMode themeMode) {
    ThemeData? newTheme;
    switch (themeMode) {
      case ThemeMode.dark:
        newTheme = ThemeData.dark();
        break;
      case ThemeMode.light:
        newTheme = ThemeData.light();
        break;
      default:
        newTheme = ThemeData.light();
    }
    // Apply the new theme
    MaterialApp app = MaterialApp(
      themeMode: themeMode,
      theme: newTheme,
      debugShowCheckedModeBanner: false,
      home: SettingsPage(),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => app),
    );
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Launcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'URL Launcher'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildButton(
              icon: Icons.call,
              label: 'Call (617) 171-9442',
              onPressed: () => _launchURL('tel:6171719442'),
            ),
            SizedBox(height: 20),
            _buildButton(
              icon: Icons.send,
              label: 'Send SMS',
              onPressed: () => _launchSMS('6171719442'),
            ),
            SizedBox(height: 20),
            _buildButton(
              icon: Icons.emergency,
              label: 'Emergency',
              buttonColor: Colors.white,
              onPressed: () => _launchURL('tel:911'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Function onPressed,
    Color? buttonColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      onPressed: onPressed as void Function()?,
      label: Text(
        label,
        style: TextStyle(fontSize: 20),
      ),
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0), // Remove elevation
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Remove rounded corners
          ),
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.grey;
            }
            return buttonColor ?? Color.fromARGB(255, 248, 238, 238);
          },
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchSMS(String phoneNumber) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': 'Hello, I want to send you a message!'},
    );

    if (await canLaunch(smsUri.toString())) {
      await launch(smsUri.toString());
    } else {
      throw 'Could not send SMS to $phoneNumber';
    }
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(
                        title: '',
                      ),
                    ),
                  );
                  // Add your onTap logic here for the Police icon
                  print('Police icon tapped!');
                  // You can replace the above print statement with your desired functionality
                },
                child: Container(
                  padding: EdgeInsets.only(
                      right: 30,
                      bottom: 18,
                      top: 18,
                      left: 30), // Adjust the padding as needed
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(
                        10.0), // Adjust the border radius as needed
                  ),
                  child: Column(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.personWalkingWithCane,
                        size: 50,
                        color: Colors.white,
                      ),
                      Text(
                        'Police',
                        style: GoogleFonts.nunito(
                            fontSize: 25, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(),
                        ),
                      );
                      // Add your onTap logic here for the Police icon
                      print('Police icon tapped!');
                      // You can replace the above print statement with your desired functionality
                    },
                    child: Container(
                      padding: EdgeInsets.only(
                          right: 30,
                          bottom: 18,
                          top: 18,
                          left: 30), // Adjust the padding as needed
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                            10.0), // Adjust the border radius as needed
                      ),
                      child: Column(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.fire,
                            size: 50,
                            color: Colors.white,
                          ),
                          Text(
                            'F i re',
                            style: GoogleFonts.nunito(
                                fontSize: 25, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 20), // Add space between the rows
      Container(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(
                        title: '',
                      ),
                    ),
                  );
                  // Add your onTap logic here for the Police icon
                  print('Police icon tapped!');
                  // You can replace the above print statement with your desired functionality
                },
                child: Container(
                  padding: EdgeInsets.only(
                      right: 30,
                      bottom: 18,
                      top: 18,
                      left: 30), // Adjust the padding as needed
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(
                        10.0), // Adjust the border radius as needed
                  ),
                  child: Column(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.ambulance,
                        size: 50,
                        color: Colors.white,
                      ),
                      Text(
                        'Ambl',
                        style: GoogleFonts.nunito(
                            fontSize: 25, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(
                            title: '',
                          ),
                        ),
                      );
                      // Add your onTap logic here for the Police icon
                      print('Police icon tapped!');
                      // You can replace the above print statement with your desired functionality
                    },
                    child: Container(
                      padding: EdgeInsets.only(
                          right: 30,
                          bottom: 18,
                          top: 18,
                          left: 30), // Adjust the padding as needed
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(
                            10.0), // Adjust the border radius as needed
                      ),
                      child: Column(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.heartCircleCheck,
                            size: 50,
                            color: Colors.white,
                          ),
                          Text(
                            ' Aids',
                            style: GoogleFonts.nunito(
                                fontSize: 25, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      Container(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(
                        title: '',
                      ),
                    ),
                  );
                  // Add your onTap logic here for the Police icon
                  print('Police icon tapped!');
                  // You can replace the above print statement with your desired functionality
                },
                child: Container(
                  padding: EdgeInsets.only(
                      right: 30,
                      bottom: 18,
                      top: 18,
                      left: 30), // Adjust the padding as needed
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(
                        10.0), // Adjust the border radius as needed
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.traffic,
                        size: 50,
                        color: Colors.white,
                      ),
                      Text(
                        'Trafic',
                        style: GoogleFonts.nunito(
                            fontSize: 25, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(
                            title: '',
                          ),
                        ),
                      );
                      // Add your onTap logic here for the Police icon
                      print('Police icon tapped!');
                      // You can replace the above print statement with your desired functionality
                    },
                    child: Container(
                      padding: EdgeInsets.only(
                          right: 30,
                          bottom: 18,
                          top: 18,
                          left: 30), // Adjust the padding as needed
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(
                            10.0), // Adjust the border radius as needed
                      ),
                      child: Column(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.comment,
                            size: 50,
                            color: Colors.white,
                          ),
                          Text(
                            'Asist',
                            style: GoogleFonts.nunito(
                                fontSize: 25, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ])));
  }
}

class Hello extends StatelessWidget {
  const Hello({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: TextButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MapScreen()));
            },
            child: Text('GPS')));
  }
}

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
    return SingleChildScrollView(
      // Wrap with SingleChildScrollView
      child: userData.isNotEmpty
          ? _buildProfileView()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.center, // Center content horizontally
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
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch, // Stretch content horizontally
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

class loadMap extends StatefulWidget {
  static const CameraPosition _center =
      CameraPosition(target: LatLng(45.521563, -122.677433), zoom: 14);

  @override
  State<loadMap> createState() => _loadMapState();
}

class _loadMapState extends State<loadMap> {
  final Completer<GoogleMapController> _map_controler = Completer();

  final List<Marker> _marker = [];

  final List<Marker> _branch = const [
    Marker(
        markerId: MarkerId('1'),
        position: LatLng(2.03711, 45.34375),
        infoWindow: InfoWindow(title: 'testing')),
    Marker(
        markerId: MarkerId('2'),
        position: LatLng(2.03711, 45.34375),
        infoWindow: InfoWindow(title: 'Mogadishu', snippet: 'testing')),
  ];

  @override
  void initState() {
    super.initState();
    _marker.addAll(_branch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: GoogleMap(
        markers: Set<Marker>.of(_marker),
        onMapCreated: (GoogleMapController controller) {
          _map_controler.complete(controller);
        },
        initialCameraPosition: loadMap._center,
      ),
    );
  }
}
