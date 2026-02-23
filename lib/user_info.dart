import 'package:flutter/material.dart';
import 'package:tankroute/home_screen.dart';
import 'package:tankroute/hoome.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  String validMobile = "9999999999";
  late String enteredMobile = _mobileController.text;
  bool showSubmitButton = false;

  // Hardcoded mobile number and OTP for validation
  // void _submitForm() {
  //   String enteredMobile = _mobileController.text;
  //   String enteredOtp = _otpController.text;
  //
  //   // Hardcoded values for validation
  //   String validMobile = "9999999999";
  //   String validOtp = "1234";
  //
  //   // Check if the entered values match the hardcoded ones
  //   if (enteredMobile == validMobile && enteredOtp == validOtp) {
  //     // If both match, navigate to the next screen
  //     _navigateToNextScreen();
  //   } else {
  //     // Show error message if validation fails
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Invalid mobile number or OTP')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(backgroundColor: Colors.lightBlueAccent),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "User Info",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Enter the mobileno, we'll send you a verification code for authentication",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 50),
              Row(
                children: [
                  const Text(
                    "Name*",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 50),
                  const Text(
                    ":",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      cursorColor: Colors.blueAccent,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter Your Name',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Text(
                    "Mobile No*",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 17),
                  const Text(
                    ":",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    color: Colors.blueAccent,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 14.0,
                      ),
                      child: Center(
                        child: Text(
                          "+91",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      cursorColor: Colors.blueAccent,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        hintText: 'Mobile Number',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        if (value.length != 10 ||
                            !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // OTP Field Row
              Row(
                children: [
                  const Text(
                    "OTP*",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 65),
                  const Text(
                    ":",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      cursorColor: Colors.blueAccent,
                      controller: _otpController,
                      decoration: const InputDecoration(
                        hintText: 'OTP',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter OTP';
                        }
                        if (value.length != 4 ||
                            !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Please enter a valid 4-digit OTP';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        enteredMobile = _mobileController.text;
                        enteredMobile == validMobile
                            ? setState(() {
                                _otpController.text = "1234";
                                showSubmitButton = true;
                              })
                            : ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter valid mobile no.',
                                  ),
                                ),
                              );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        // Button background color
                        minimumSize: const Size(double.infinity, 50),
                        // Full width button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius
                              .zero, // Rectangle shape (no rounded corners)
                        ),
                      ),
                      child: const Text(
                        "GET OTP",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16, // White text color
                        ),
                        textAlign: TextAlign.center, // ensures centered text
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              if (showSubmitButton)
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      enteredMobile = _mobileController.text;
                      // Check if the entered mobile number is valid
                      if (enteredMobile == validMobile) {
                        setState(() {
                          // Set OTP and prepare for next screen navigation
                          _otpController.text =
                              "1234"; // Set OTP for valid number
                          showSubmitButton =
                              false; // Hide the button after submission

                          // Navigate to HomeScreen after validation
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                name: _nameController.text,
                                phoneNumber: _mobileController.text,
                              ),
                            ),
                          );
                        });
                      } else {
                        // Show an error message if the number is invalid
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter valid mobile no.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius
                            .zero, // Rectangle shape (no rounded corners)
                      ),
                    ),
                    child: const Text(
                      "SUBMIT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        bottomNavigationBar: Container(
          height: 25,

          color: Colors.blue,
          child: Center(
            child: Text(
              "K-GIS, KSRSAC",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
