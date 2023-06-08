import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rolebasedlogin/facultyregister.dart';
import 'login.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Teacher extends StatefulWidget {
  const Teacher({Key? key}) : super(key: key);

  @override
  State<Teacher> createState() => _TeacherState();
}

class MyData {
  final String name;
  final String roll;
  final String time;
  final String reason;
  final String documentId;

  final String date;
  final String year;

  MyData({
    required this.name,
    required this.roll,
    required this.time,
    required this.reason,
    required this.documentId,
    required this.date,
    required this.year,
  });
}

class _TeacherState extends State<Teacher> {
  // Flutter Local Notifications plugin instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  String _currentDepartmentSelected = '';
  List<String> departmentOptions = [];
  String _currentUserDepartment = '';
  int _prevApplicationCount = 0;

  @override
  void initState() {
    departmentOptions = ['CSE', 'ECE', 'EEE', 'CE', 'ME'];
    _currentDepartmentSelected =
    departmentOptions.isNotEmpty ? departmentOptions[0] : '';
    fetchCurrentUserDepartment();
    initializeNotifications();
    super.initState();
  }

  // Initialize Flutter Local Notifications plugin
  void initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Display a notification with the given title and body
  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      '1',
      'outpass request',
      'displays new outpass request',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'notification_payload',
    );
  }

  Future<void> fetchCurrentUserDepartment() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userSnapshot.exists) {
        setState(() {
          _currentUserDepartment = userSnapshot['department'];
        });
      }
    }
  }

  Future<void> recommendApplication(String applicationId) async {
    // Get the document snapshot from outpassform$_currentUserDepartment
    DocumentSnapshot applicationSnapshot = await FirebaseFirestore.instance
        .collection('facultyapproved$_currentUserDepartment')
        .doc(applicationId)
        .get();

    // Store the document in approvedRequests collection
    await FirebaseFirestore.instance
        .collection('approvedRequests')
        .doc(applicationId)
        .set(applicationSnapshot.data() as Map<String, dynamic>);

    // Delete the document from outpassform$_currentUserDepartment collection
    await FirebaseFirestore.instance
        .collection('facultyapproved$_currentUserDepartment')
        .doc(applicationId)
        .delete();

    // Show a Snackbar message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Approved',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> deleteApplication(String applicationId) async {
    // Delete the document from outpassform$_currentUserDepartment collection
    await FirebaseFirestore.instance
        .collection('facultyapproved$_currentUserDepartment')
        .doc(applicationId)
        .delete();

    // Show a Snackbar message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Denied',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school), // Teacher icon
            const SizedBox(
                width: 8), // Add some spacing between the icon and the title
            const Text("HOD"), // Title text
          ],
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
    IconButton(
    onPressed: () {
    // Navigate to the registration page
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => FacultyRegisterPage(),
    ),
    );
    },
    icon: const Icon(Icons.person_add),
    )],
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            if (_currentUserDepartment.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('facultyapproved$_currentUserDepartment')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<DocumentSnapshot> documents = snapshot.data!.docs;
                    int currentApplicationCount = documents.length;

                    // Show notification when a new request is added
                    if (_prevApplicationCount < currentApplicationCount) {
                      DocumentChange change = snapshot.data!.docChanges.last;
                      final data = change.doc.data() as Map<String, dynamic>?;



                      final MyData newData = MyData(
                        documentId: change.doc.id,
                        name: change.doc['name'],
                        roll: change.doc['roll'],
                        time: change.doc['time'],
                        reason: change.doc['reason'],

                        date: change.doc['date'],
                        year: change.doc['year'],
                      );







                      showNotification(
                        'New Request',
                        'Request by ${newData.name}',
                      );
                    }
                    _prevApplicationCount = currentApplicationCount;

                    return Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: documents.length,
                              itemBuilder: (context, index) {
                                DocumentSnapshot document = documents[index];

                                return ListTile(
                                  title: Text("Application Number: ${document['applicationNumber']}"),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Name: ${document['name']}"),
                                      Text("Department: ${document['department']}"),
                                      Text("Year: ${document['year']}"),
                                      Text("Reason: ${document['reason']}"),
                                      Text("Roll No: ${document['roll']}"),
                                      Text("Time: ${document['time']}"),
                                      Text("Date: ${document['date']}"),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              recommendApplication(document.id);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              primary: Colors.green,
                                            ),
                                            child: Text("Recommend"),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              deleteApplication(document.id);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              primary: Colors.red,
                                            ),
                                            child: Text("Not Recommend"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );

                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }
}





