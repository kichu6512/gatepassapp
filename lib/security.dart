import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'login.dart';

class SecurityPage extends StatefulWidget {

  const SecurityPage({Key? key}) : super(key: key);

  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _securityDataStream;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _securityDataStream = _firestore
        .collection('securitydata')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _logout(BuildContext context) async {
    await _firebaseAuth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Page'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              _logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Student OUT Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _securityDataStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data!.docs;

                if (data.isEmpty) {
                  return const Center(
                    child: Text('No data available'),
                  );
                }

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final document = data[index];
                    return _buildListTile(document);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanQRCode,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildListTile(DocumentSnapshot document) {
    final scanResult = document.get('scanResult') as String;
    final applicationNumber = _extractApplicationNumber(scanResult);
    final timestamp = document.get('timestamp') as Timestamp?;
    final formattedTimestamp = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : 'No timestamp available';

    return FutureBuilder<DocumentSnapshot>(
      future:
      _firestore.collection('finalapproval').doc(applicationNumber).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Loading...'),
          );
        }

        final finalApprovalDoc = snapshot.data!;
        if (finalApprovalDoc.exists) {
          final name = finalApprovalDoc.get('name') as String;
          final reason = finalApprovalDoc.get('reason') as String;
          return ListTile(
            title: Text(applicationNumber),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: $name'),
                Text('Time: $formattedTimestamp'),
                Text('Reason: $reason'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.red,
                size: 30,
              ),
              onPressed: () {
                _removeListFromDatabase(document.id);
              },
            ),
          );
        } else {
          if (scanResult != '-1') {
            _showOutpassNotExistDialog(context);
          }

          return ListTile(
            title: Text(applicationNumber),
            subtitle: const Text('Outpass does not exist'),
            trailing: InkWell(
              onTap: () {
                _removeListFromDatabase(document.id);
              },
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 30,
              ),
            ),
          );
        }
      },
    );
  }

  String _extractApplicationNumber(String scanResult) {
    final RegExp applicationNumberRegex =
    RegExp(r'Application Number: ([A-Za-z0-9]+)');
    final Match? match = applicationNumberRegex.firstMatch(scanResult);
    return match?.group(1) ?? 'N/A';
  }

  Future<void> _removeListFromDatabase(String documentId) async {
    try {
      await _firestore.collection('securitydata').doc(documentId).delete();
    } catch (e) {
      print('Error removing list from database: $e');
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  Future<void> _scanQRCode() async {
    try {
      final scanResult = await FlutterBarcodeScanner.scanBarcode(
        '#FF0000', // The color of the toolbar
        'Cancel', // The text for the cancel button
        true, // Show flash icon
        ScanMode.QR, // Specify the scan mode (QR, BARCODE, or DEFAULT)
      );

      if (scanResult != '-1') {
        final applicationNumber = _extractApplicationNumber(scanResult);
        final finalApprovalDoc = await _firestore
            .collection('finalapproval')
            .doc(applicationNumber)
            .get();

        if (finalApprovalDoc.exists) {
          await _storeQRCodeData(scanResult);
          final scaffoldContext = context; // Assign the BuildContext to a local variable
          _playAudioMessage('Outpass verified');
          _showSnackbar(scaffoldContext, 'Outpass verified');
        } else {
          _showOutpassNotExistDialog(context);
        }
      }

      setState(() {
        // No need to set qrText anymore, as it's not being used in this version
      });
    } catch (e) {
      print('Error scanning QR code: $e');
    }
  }

  Future<void> _storeQRCodeData(String scanResult) async {
    try {
      final QuerySnapshot existingData = await _firestore
          .collection('securitydata')
          .where('scanResult', isEqualTo: scanResult)
          .limit(1)
          .get();

      if (existingData.docs.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('QR Code Expired'),
              content: const Text('This QR code has already been scanned.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        Future.delayed(const Duration(seconds: 2), () {
          _playAudioMessage('QR Code Expired');
        });
      } else {
        await _firestore.collection('securitydata').add({
          'scanResult': scanResult,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error storing QR code data: $e');
    }
  }


  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _playAudioMessage(String message) async {
    await flutterTts.speak(message);
  }

  void _showOutpassNotExistDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Outpass does not exist'),
          content: const Text(
            'The scanned QR code does not correspond to an existing outpass.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    await Future.delayed(Duration(milliseconds: 500)); // Delay for 500 milliseconds (adjust as needed)
    _playAudioMessage('Verification Failed');
  }


}
