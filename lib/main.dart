import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rolebasedlogin/principal.dart';
import 'register.dart';
import 'student.dart';
import 'teacher.dart';

import 'security.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class UserRoles {
  static const String student = 'Student';
  static const String principal = 'Principal';
  static const String teacher = 'Teacher';
  static const String security = 'Security';
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    initializeNotifications();

  }

  void initializeNotifications() {
    var initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }



  @override
  Widget build(BuildContext context) {
    // Check if the user is authenticated
    if (user != null) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!.data();
            if (data != null && data['role'] != null) {
              final role = data['role'] as String; // Cast the value to String
              if (role == UserRoles.student) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primaryColor: Colors.blue[900],
                  ),
                  home: Student(),
                );
              } else if (role == UserRoles.principal) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primaryColor: Colors.blue[900],
                  ),
                  home: Principal(),
                );
              } else if (role == UserRoles.teacher) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primaryColor: Colors.blue[900],
                  ),
                  home: Teacher(),
                );
              } else if (role == UserRoles.security) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primaryColor: Colors.blue[900],
                  ),
                  home: SecurityPage(),
                );
              }
            }
          }
          // If the user does not have a role or the data is not available, display the register screen
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: Colors.blue[900],
            ),
            home: SplashScreen(),
          );
        },
      );
    }

    // If the user is not authenticated, display the register screen
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue[900],
      ),
      home: SplashScreen(),
    );
  }
}

// splash screen
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateToRegister(); // Add a method to navigate to the Register screen after a certain duration
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/gplogo3.png'),
          ],
        ),
      ),
    );
  }

  void navigateToRegister() async {
    await Future.delayed(const Duration(seconds: 2)); // Add a delay of 2 seconds
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Register()),
    );
  }
}

