import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class FacultyPage extends StatelessWidget {
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String uid = currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Faculty'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: Icon(Icons.logout),
          ),
        ],backgroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          final userDocument = snapshot.data;

          if (!userDocument!.exists) {
            return Text('User document does not exist');
          }

          final department = userDocument['department'];
          final year = userDocument['year'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('outpassform$department$year').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              final outpassForms = snapshot.data!.docs;

              return ListView.builder(
                itemCount: outpassForms.length,
                itemBuilder: (context, index) {
                  final outpassForm = outpassForms[index];

                  void recommend() {
                    final approvedCollection =
                    FirebaseFirestore.instance.collection('facultyapproved$department');
                    approvedCollection.doc(outpassForm['applicationNumber']).set({
                      'applicationNumber': outpassForm['applicationNumber'],
                      'name': outpassForm['name'],
                      'email': outpassForm['email'],
                      'roll': outpassForm['roll'],
                      'department': outpassForm['department'],
                      'year': outpassForm['year'],
                      'date': outpassForm['date'],
                      'time': outpassForm['time'],
                      'reason': outpassForm['reason'],
                    });

                    final requestDoc =
                    FirebaseFirestore.instance.doc('outpassform$department$year/${outpassForm.id}');
                    requestDoc.delete();
                  }

                  void notRecommend() {
                    final requestDoc =
                    FirebaseFirestore.instance.doc('outpassform$department$year/${outpassForm.id}');
                    requestDoc.delete();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text('Name: ${outpassForm['name']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('applicationNumber: ${outpassForm['applicationNumber']}'),
                            Text('Email ID: ${outpassForm['email']}'),
                            Text('Roll No: ${outpassForm['roll']}'),
                            Text('Department: ${outpassForm['department']}'),
                            Text('Year: ${outpassForm['year']}'),
                            Text('Date: ${outpassForm['date']}'),
                            Text('Time: ${outpassForm['time']}'),
                            Text('Reason: ${outpassForm['reason']}'),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: recommend,
                            style: ElevatedButton.styleFrom(primary: Colors.green),
                            child: Text('Recommend'),
                          ),
                          SizedBox(width: 8.0),
                          ElevatedButton(
                            onPressed: notRecommend,
                            style: ElevatedButton.styleFrom(primary: Colors.red),
                            child: Text('Not Recommend'),
                          ),
                          SizedBox(width: 16.0),
                        ],
                      ),
                      Divider(
                        color: Colors.grey,
                        thickness: 1.0,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}








