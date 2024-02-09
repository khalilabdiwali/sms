import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sms/ChatScreen.dart';
import 'package:sms/LoginPage.dart';
import 'package:sms/home.dart';
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
//for settings
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _iconBool ? _darkTheme : _lightTheme,
    home: LoginPage(),
  ));
}

//for dark mode
// void main() {
//   runApp(
//     home(),
//   );
// }

