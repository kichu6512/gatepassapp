import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'login.dart';
import 'principal.dart';
import 'status.dart';

class Student extends StatefulWidget {
  const Student({Key? key}) : super(key: key);

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  String _currentDepartmentSelected = '';
  List<String> departmentOptions = [];

  String _currentYearSelected = '';
  List<String> yearOptions = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    departmentOptions = ['CSE', 'ECE', 'EEE', 'CE', 'ME'];
    _currentDepartmentSelected = departmentOptions.isNotEmpty ? departmentOptions[0] : '';

    yearOptions = ['1', '2', '3', '4'];
    _currentYearSelected = yearOptions.isNotEmpty ? yearOptions[0] : '';

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school),
            const SizedBox(width: 8),
            const Text("Student"),
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
        ],
      ),
      backgroundColor: const Color(0xFFFFFFFF),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Fill the Application Form",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _rollController,
                      decoration: const InputDecoration(labelText: 'Roll No'),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your roll no';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _currentYearSelected,
                      decoration: const InputDecoration(labelText: 'Year'),
                      onChanged: (newValue) {
                        setState(() {
                          _currentYearSelected = newValue!;
                        });
                      },
                      items: yearOptions.map((year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                    ),
                    GestureDetector(
                      onTap: () {
                        _selectDate(context);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(labelText: 'Date'),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please select a date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(labelText: 'Time'),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter the time';
                        }
                        return null;
                      },
                      onTap: () async {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (selectedTime != null) {
                          String formattedTime = DateFormat.Hm().format(
                            DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                              selectedTime.hour,
                              selectedTime.minute,
                            ),
                          );
                          _timeController.text = formattedTime;
                        }
                      },
                    ),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Reason'),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a reason';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    DropdownButtonFormField<String>(
                      value: _currentDepartmentSelected,
                      decoration: const InputDecoration(labelText: 'Department'),
                      onChanged: (newValue) {
                        setState(() {
                          _currentDepartmentSelected = newValue!;
                        });
                      },
                      items: departmentOptions.map((department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Text(department),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String name = _nameController.text;
                          String email = _emailController.text;
                          String roll = _rollController.text;
                          String year = _currentYearSelected;
                          String date = _dateController.text;
                          String time = _timeController.text;
                          String reason = _reasonController.text;
                          String department = _currentDepartmentSelected;

                          // Store data into Firestore
                          try {
                            User? user = FirebaseAuth.instance.currentUser;

                            String collectionName = 'outpassform$department$year';

                            DocumentReference docRef = await FirebaseFirestore
                                .instance
                                .collection(collectionName)
                                .add({
                              'name': name,
                              'email': email,
                              'roll': roll,
                              'year': year,
                              'date': date,
                              'time': time,
                              'reason': reason,
                              'department': department,
                              'applicationNumber': '',
                            });

                            // Update the document with the application number
                            await docRef.update({'applicationNumber': docRef.id});

                            // Clear the form fields
                            _nameController.clear();
                            _emailController.clear();
                            _rollController.clear();
                            _dateController.clear();
                            _timeController.clear();
                            _reasonController.clear();

                            // Get the application number
                            String applicationNumber = docRef.id;

                            // Show success message with the application number
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Application Submitted'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Your application has been successfully submitted.\nApplication Number: $applicationNumber'),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Kindly note the application number.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: applicationNumber));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Application Number Copied to Clipboard')),
                                          );
                                        },
                                        icon: const Icon(Icons.copy),
                                        label: const Text('Copy to Clipboard'),
                                      ),
                                    ],
                                  ),
                                  actions: <Widget>[
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
                          } catch (e) {
                            // Handle any errors that occur during the Firestore operation
                            print('Error saving form data: $e');
                          }
                        }
                      },
                      child: const Text('Submit'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatusPage(),
                          ),
                        );
                      },
                      child: const Text('Status'),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
      _dateController.text = formattedDate;
    }
  }
}
