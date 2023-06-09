import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({Key? key}) : super(key: key);

  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  TextEditingController _applicationNumberController = TextEditingController();
  String _currentUserDepartment = '';
  String? _selectedYear;
  List<String> _yearOptions = ['1', '2', '3', '4'];

  @override
  void initState() {
    fetchCurrentUserDepartment();
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _applicationNumberController,
                decoration:
                    const InputDecoration(labelText: 'Application Number'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedYear = newValue;
                  });
                },
                items:
                    _yearOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Year',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Retrieve the entered application number
                  String applicationNumber = _applicationNumberController.text;

                  // Check if the application number exists in the outpassform$_currentUserDepartment$_selectedYear collection
                  DocumentSnapshot outpassFormSnapshot = await FirebaseFirestore
                      .instance
                      .collection(
                          'outpassform$_currentUserDepartment$_selectedYear')
                      .doc(applicationNumber)
                      .get();

                  if (outpassFormSnapshot.exists) {
                    // Application number exists in outpassform$_currentUserDepartment$_selectedYear collection
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Status: Pending'),
                          content: const Text('Faculty Verification pending.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    // Check if the application number exists in the facultyapproved collection
                    DocumentSnapshot approvedRequestSnapshot =
                        await FirebaseFirestore.instance
                            .collection(
                                'facultyapproved$_currentUserDepartment')
                            .doc(applicationNumber)
                            .get();

                    if (approvedRequestSnapshot.exists) {
                      // Application number exists in approvedRequests collection
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Status: Pending'),
                            content: const Text('HOD Approval pending.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // Check if the application number exists in the approvedRequests collection
                      DocumentSnapshot approvedRequestSnapshot =
                          await FirebaseFirestore.instance
                              .collection('approvedRequests')
                              .doc(applicationNumber)
                              .get();

                      if (approvedRequestSnapshot.exists) {
                        // Application number exists in approvedRequests collection
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Status: Pending'),
                              content:
                                  const Text('Principal Approval pending.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        // Check if the application number exists in the finalapproval collection
                        DocumentSnapshot finalApprovalSnapshot =
                            await FirebaseFirestore.instance
                                .collection('finalapproval')
                                .doc(applicationNumber)
                                .get();

                        if (finalApprovalSnapshot.exists) {
                          // Application number exists in finalapproval collection
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                contentPadding: const EdgeInsets.fromLTRB(
                                    24.0, 20.0, 24.0, 0),
                                title: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8.0),
                                      const Text(
                                        'Outpass Granted',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 150.0,
                                          height: 150.0,
                                          child: QrImage(
                                            data:
                                                'Application Number: $applicationNumber\nName: ${finalApprovalSnapshot['name']}\nTime: ${finalApprovalSnapshot['time']}\nDate: ${DateTime.now().toString()}\nReason: ${finalApprovalSnapshot['reason']}',
                                            version: QrVersions.auto,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      const Center(
                                        child: Text(
                                          'SCAN ME!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      const Center(
                                        child: Text(
                                          'NOTE: QR CODE EXPIRES AFTER SCANNING',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      const Text(
                                          'Your outpass has been granted.'),
                                      const SizedBox(height: 8.0),
                                      const Text(
                                        'Details:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        'Application Number: $applicationNumber\nName: ${finalApprovalSnapshot['name']}\nTime: ${finalApprovalSnapshot['time']}\nDate: ${DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal())}\nReason: ${finalApprovalSnapshot['reason']}',
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                            // Set the background color of the dialog box
                            barrierColor: Colors.greenAccent.withOpacity(1),
                          );
                        } else {
                          // Application number does not exist in any collection
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8.0),
                                    const Text('Outpass Denied'),
                                  ],
                                ),
                                content: const Text(
                                    'Contact HOD for more information'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                            // Set the background color of the dialog box
                            barrierColor: Colors.red.withOpacity(1),
                          );
                        }
                      }
                    }
                    // Clear the text field
                    _applicationNumberController.clear();
                  }
                },
                child: const Text('Check Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
