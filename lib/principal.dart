import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MyData {
  final String applicationNumber;
  final String name;
  final String roll;
  final String time;
  final String reason;
  final String email;
  final String date;

  MyData({
    required this.applicationNumber,
    required this.name,
    required this.roll,
    required this.time,
    required this.reason,
    required this.email,
    required this.date,
  });
}


class Principal extends StatefulWidget {
  const Principal({Key? key}) : super(key: key);

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  final CollectionReference _approvedRequestsCollection =
  FirebaseFirestore.instance.collection('approvedRequests');
  final CollectionReference _finalApprovalCollection =
  FirebaseFirestore.instance.collection('finalapproval');
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  late Stream<List<MyData>> _dataListStream;

  @override
  void initState() {
    super.initState();
    _dataListStream = fetchDataFromFirestore();
    listenToCollectionChanges();
    initializeNotifications();

  }


  void initializeNotifications() {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }


  void listenToCollectionChanges() {
    _approvedRequestsCollection.snapshots().listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        final change = snapshot.docChanges.first;
        if (change.type == DocumentChangeType.added) {
          // New document added to the approvedRequests collection
          final MyData newData = MyData(
            applicationNumber: change.doc.id,
            name: change.doc['name'],
            roll: change.doc['roll'],
            time: change.doc['time'],
            reason: change.doc['reason'],
            email: change.doc['email'],
            date: change.doc['date'],
          );
          showNotification('New Request', 'Request by ${newData.name} is Recommended.');
        }

      }
    });
  }

  void showNotification(String title, String message) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      '6512',
      'approved requests',
      'requests recommended by HOD',
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
    return _approvedRequestsCollection
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      return querySnapshot.docs.map((QueryDocumentSnapshot doc) {
        return MyData(
          applicationNumber: doc.id,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Principal"), // Title text
          ],
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () async {
              await logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),



      body: buildDataListWidget(),
    );
  }

  Widget buildDataListWidget() {
    return StreamBuilder<List<MyData>>(
      stream: _dataListStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final dataList = snapshot.data!;

        return ListView.separated(
          itemCount: dataList.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (BuildContext context, int index) {
            final data = dataList[index];

            return buildListItem(data, dataList, index);
          },
        );
      },
    );
  }

  Widget buildListItem(MyData data, List<MyData> dataList, int index) {
    return ListTile(
      title: Text(data.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application Number: ${data.applicationNumber}'),
          Text('Roll: ${data.roll}'),
          Text('Time: ${data.time}'),
          Text('Reason: ${data.reason}'),
          Text('Email: ${data.email}'),
          Text('Date: ${data.date}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              await approveRequest(data, dataList, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
          const SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: () async {
              await denyRequest(data, dataList, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deny'),
          ),
        ],
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

  Future<void> approveRequest(
      MyData data, List<MyData> dataList, int index) async {
    try {
      // Store approved details in the finalapproval collection
      await _finalApprovalCollection.doc(data.applicationNumber).set({
        'name': data.name,
        'roll': data.roll,
        'time': data.time,
        'date': data.date,
        'reason': data.reason,
        'applicationNumber': data.applicationNumber,
        'email': data.email,
      });

      // Remove the approved request from the approvedRequests collection
      await _approvedRequestsCollection.doc(data.applicationNumber).delete();

      print('Approved: ${data.name}');

      setState(() {
        // Remove the approved request from the dataList
        dataList.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved: ${data.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (error) {
      print('Error approving request: $error');
    }
  }


  Future<void> denyRequest(
      MyData data, List<MyData> dataList, int index) async {
    try {
      // Remove the request from the approvedRequests collection
      await _approvedRequestsCollection.doc(data.applicationNumber).delete();

      print('Denied: ${data.name}');

      setState(() {
        // Remove the denied request from the dataList
        dataList.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Denied: ${data.name}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (error) {
      print('Error denying request: $error');
    }
  }
}


