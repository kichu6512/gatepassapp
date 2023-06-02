import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'login.dart';

class MyData {
  final String name;
  final String roll;
  final String time;
  final String reason;
  final String documentId;
  final String email;
  final String date;

  MyData({
    required this.name,
    required this.roll,
    required this.time,
    required this.reason,
    required this.documentId,
    required this.email,
    required this.date,
  });
}

class Teacher extends StatefulWidget {
  const Teacher({Key? key}) : super(key: key);

  @override
  State<Teacher> createState() => _TeacherState();
}

class _TeacherState extends State<Teacher> {
  final CollectionReference _outpassformCollection =
  FirebaseFirestore.instance.collection('outpassform');
  late Stream<List<MyData>> _dataListStream;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  Stream<List<MyData>> dataStream = FirebaseFirestore.instance
      .collection('outpassform')
      .snapshots()
      .map((querySnapshot) => querySnapshot.docs.map((doc) {
    return MyData(
      name: doc['name'],
      roll: doc['roll'],
      time: doc['time'],
      reason: doc['reason'],
      documentId: doc.id,
      email: doc['email'],
      date: doc['date'], // Include the date field
    );
  }).toList());

  late String department; // Added department variable

  @override
  void initState() {
    super.initState();
    _dataListStream = fetchDataFromFirestore();
    listenToCollectionChanges();
    initializeNotifications();
    fetchCurrentUserDepartment(); // Fetch department

  }

  void initializeNotifications() {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic');

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void listenToCollectionChanges() {
    _outpassformCollection.snapshots().listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        final change = snapshot.docChanges.first;
        if (change.type == DocumentChangeType.added) {
          // New document added to the approvedRequests collection
          final MyData newData = MyData(
            documentId: change.doc.id,
            name: change.doc['name'],
            roll: change.doc['roll'],
            time: change.doc['time'],
            reason: change.doc['reason'],
            email: change.doc['email'],
            date: change.doc['date'],
          );
          showNotification('New Request', 'Request by ${newData.name}');
        }
        // You can handle other types of changes (modified or removed) if needed.
      }
    });
  }

  void showNotification(String title, String message) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      '6512',
      'studentrequest',
      'receives outpass requests',
      importance: Importance.max,
      priority: Priority.high,
    );

    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      message,
      platformChannelSpecifics,
      payload: 'notification_payload',
    );
  }

  Stream<List<MyData>> fetchDataFromFirestore() {
    return _outpassformCollection.snapshots().map((QuerySnapshot querySnapshot) {
      return querySnapshot.docs.map((QueryDocumentSnapshot doc) {
        return MyData(
          documentId: doc.id,
          name: doc['name'],
          roll: doc['roll'],
          time: doc['time'],
          reason: doc['reason'],
          email: doc['email'],
          date: doc['date'],
        );
      }).toList();
    });
  }

  List<MyData> dataList = []; // Added declaration here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HOD"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<MyData>>(
        stream: dataStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching data: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          dataList = snapshot.data ?? []; // Update the dataList

          return ListView.builder(
            itemCount: dataList.length,
            itemBuilder: (BuildContext context, int index) {
              MyData data = dataList[index];

              return ListTile(
                title: Text(data.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${data.email}'),
                    Text('Roll No: ${data.roll}'),
                    Text('Time: ${data.time}'),
                    Text('Reason: ${data.reason}'),
                    Text('Date: ${data.date}'), // Display the date field
                    Text('Application Number: ${data.documentId}'),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            approveRequest(data, index);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Recommend'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            denyRequest(data);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Not Recommend'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void fetchCurrentUserDepartment() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(userId)
            .get();
        if (snapshot.exists) {
          setState(() {
            department = snapshot['department'];
          });
        }
      }
    } catch (error) {
      print('Error fetching current user department: $error');
    }
  }

  void approveRequest(MyData data, int index) async {
    String applicationNumber = data.documentId;
    String email = data.email;
    try {
      await FirebaseFirestore.instance
          .collection('approvedRequests')
          .doc(applicationNumber)
          .set({
        'name': data.name,
        'roll': data.roll,
        'time': data.time,
        'date': data.date,
        'reason': data.reason,
        'applicationNumber': applicationNumber,
        'email': email,
      });

      await FirebaseFirestore.instance
          .collection('outpassform')
          .doc(applicationNumber)
          .delete();

      setState(() {
        dataList.removeWhere((item) => item.documentId == applicationNumber);
      });

      // Send notification to user
      sendNotification(email, 'Your request has been recommended');
    } catch (error) {
      print('Error approving request: $error');
    }
  }

  void denyRequest(MyData data) async {
    String applicationNumber = data.documentId;
    String email = data.email;
    try {
      await FirebaseFirestore.instance
          .collection('deniedRequests')
          .doc(applicationNumber)
          .set({
        'name': data.name,
        'roll': data.roll,
        'time': data.time,
        'date': data.date,
        'reason': data.reason,
        'applicationNumber': applicationNumber,
        'email': email,
      });

      await FirebaseFirestore.instance
          .collection('outpassform')
          .doc(applicationNumber)
          .delete();

      setState(() {
        dataList.removeWhere((item) => item.documentId == applicationNumber);
      });

      // Send notification to user
      sendNotification(email, 'Your request has been not recommended');
    } catch (error) {
      print('Error denying request: $error');
    }
  }

  void sendNotification(String email, String message) {
    // Implement your logic to send notification to the user with the provided email
  }

  void logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
      );
    } catch (error) {
      print('Error signing out: $error');
    }
  }
}

void main() {
  runApp(MaterialApp(
    title: 'My App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: Teacher(),
  ));
}



