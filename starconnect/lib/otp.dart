import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String url = 'http://ec2-3-110-172-225.ap-south-1.compute.amazonaws.com:3000/fan/verifyOTP';

class OTPVerificationScreen extends StatefulWidget {
  final String email; // Add this line

  const OTPVerificationScreen({super.key, required this.email}); // Modify this line

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verifyOTP(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final String otp = _otpController.text;

      // Replace with your backend endpoint for OTP verification
      const String endpoint = "$url/verify-otp";

      Map<String, String> reqBody = {
        'otp': otp,
        'email': widget.email // Use widget.email here
      };

      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },  
          body: jsonEncode(reqBody),
        );
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (response.statusCode == 200) {
          // If the server returns a 200 OK response, navigate to the home screen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => const HomeScreen(userName: "User"), // Adjust as necessary
          //   ),
          // );
        } else {
          // If the server did not return a 200 OK response, show an error message
          _showErrorDialog(context);
        }
      } catch (e) {
        // If there was an error during the HTTP request, show an error message
        _showErrorDialog(context);
      }
    }
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Verification Failed',
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Please try again later.',
            style: GoogleFonts.readexPro(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: GoogleFonts.readexPro(),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (value.length != 4) {
      return 'OTP must be 4 digits long';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Verify OTP',
                  style: GoogleFonts.readexPro(
                    fontSize: 40.0,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF4F5FC),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  style: GoogleFonts.readexPro(
                    color: const Color(0xFFF4F5FC),
                  ),
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    labelStyle: GoogleFonts.readexPro(
                      color: const Color(0xFFF4F5FC),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF8EBBFF)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF8EBBFF)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: _validateOTP,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(   
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _verifyOTP(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: const Color(0xFF171c2e),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Verify OTP',
                      style: GoogleFonts.readexPro(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF171c2e),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
