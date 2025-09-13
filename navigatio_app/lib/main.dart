import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'dart:convert';
import 'package:http/http.dart' as http;

bool showPhoneField = false;
bool showOtpField = false;

final TextEditingController _otpController = TextEditingController();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Navigatio',
            style: TextStyle(
              color: Color.fromARGB(255, 236, 233, 233),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Color.fromARGB(255, 29, 29, 30),
          centerTitle: true,
          elevation: 4.0,
          toolbarHeight: 70,
          leading: IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              print('Menu button pressed');
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                print('Search button pressed');
              },
            ),
          ],
        ),
        body: Align(
          alignment: Alignment(0, -0.5),
          child: SingleChildScrollView(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(16.0),
              child: LoginForm(),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Full Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter your full name' : null,
          ),
          SizedBox(height: 12),

          // Email field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Official Email',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Please enter your email' : null,
          ),
          SizedBox(height: 12),

          //Phone number field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your phone number';
              if (value.length < 10) return 'Enter a valid number';
              return null;
            },
          ),
          SizedBox(height: 16),

          // Login Button
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                String name = _nameController.text.trim();
                String email = _emailController.text.trim();
                String phone = _phoneController.text.trim();

                try {
                  // Show Loading Indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Prevent closing dialog by tapping outside
                    builder: (BuildContext context) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );

                  final response = await http.post(
                    Uri.parse('http://10.0.2.2:3000/verify-user'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      "name": name,
                      "email": email,
                      "phone": phone
                    }),
                  );

                  Navigator.of(context).pop(); // Close the loading dialog

                  if (response.statusCode == 200) {
                    final result = jsonDecode(response.body);
                    print('Backend result:====');
                    print(result.runtimeType);
                    if (result['valid']) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      // SnackBar(content: Text('Login Success'))
                      // );
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OtpPage(
                        phone: _phoneController.text.trim(),   // example phone
                        email: _emailController.text.trim(), // example email
                      )),
                    );
                      
                      // Navigate to next screen if needed
                    } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid credentials')),
                        );
                      }
                    } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Server error: ${response.statusCode}')),
                        );
                      }
                } catch (e) {
                  Navigator.of(context).pop(); // Close the loading dialog if error happens
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
              }
            },
            child: Text('Next'),
          ),

        ],
      ),
    );
  }
}

class OtpPage extends StatefulWidget {
  final String? phone;
  final String? email;

  OtpPage({this.phone, this.email});

  
  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  //final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? verificationId;
  bool showOtpField = false;
  String selectedMethod = "phone"; // default

   // For email OTP simulation
  String? generatedEmailOtp;

    /// ---- PHONE OTP ----

  Future<void> sendPhoneOtp() async {
    
    await FirebaseAuth.instance.verifyPhoneNumber(
      //phoneNumber: _phoneController.text.trim(),
      // phoneNumber: widget.phone
      phoneNumber: widget.phone ?? '+11234567890',

      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone verified automatically"))
        );
        
      },

      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}"))
        );
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          showOtpField = true;

        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP Sent via Phone"))
        );
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },

    );
    

  }

 Future<void> verifyPhoneOtp() async {
  try {
    // Avoid double sign-in if auto verification succeeded
    print('==== verificationId in verifyphoneOtp: $verificationId');

    // final currentUser = FirebaseAuth.instance.currentUser;
    // print('user: $currentUser');
    // print(currentUser.runtimeType);
    // if (currentUser != null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("Already verified"))
    //   );
    //   //return;
    // }

    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId!,
      //smsCode: _otpController.text.trim(),
      smsCode: '123456',
    );
    print('Credential Type============');
    print(credential.runtimeType);
    print('OTP Entered:============');
    print(_otpController.text.trim());

    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      print("Signed in successfully");
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
    } catch (e) {
      print("General Exception: $e");
    }
    print("I am here after authentication");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Phone Verified Successfully"))
    );

  } catch (e) {
    print('ERROR:====${e.toString()}');
    print('EXCEPTION TYPE: ${e.runtimeType}');
    print('EXCEPTION: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid OTP: ${e.toString()}"))
    );
  }
}
/// ---- EMAIL OTP (simulated) ----
 Future<void> sendEmailOtp() async {
  final random = Random();
  generatedEmailOtp = (100000 + random.nextInt(899999)).toString();

  print("Generated Email OTP: $generatedEmailOtp");

  final response = await http.post(
    Uri.parse("http://10.0.2.2:3000/send-email-otp"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": widget.email,
      "otp": generatedEmailOtp,
    }),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("OTP sent to email: ${widget.email}")),
    );
    setState(() {
      showOtpField = true;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to send OTP")),
    );
  }
}

  Future<void> verifyEmailOtp() async {
    if (_otpController.text.trim() == generatedEmailOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email Verified Successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid Email OTP")),
      );
    }
  }

  /// ---- Common Function ----
  void sendOtp() {
    if (selectedMethod == "phone") {
      sendPhoneOtp();
    } else {
      sendEmailOtp();
    }
  }

  void verifyOtp() {
    if (selectedMethod == "phone") {
      verifyPhoneOtp();
    } else {
      verifyEmailOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OTP Verification")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Radio to select method
            Row(
              children: [
                Radio(
                  value: "phone",
                  groupValue: selectedMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedMethod = value.toString();
                    });
                  },
                ),
                Text("Phone"),
                Radio(
                  value: "email",
                  groupValue: selectedMethod,
                  onChanged: (value) {
                    setState(() {
                      selectedMethod = value.toString();
                    });
                  },
                ),
                Text("Email"),
              ],
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: sendOtp,
              child: Text("Send OTP"),
            ),

            if (showOtpField) ...[
              SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(labelText: "Enter OTP"),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: verifyOtp,
                child: Text("Verify OTP"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
 