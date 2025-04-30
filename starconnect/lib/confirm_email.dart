import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp.dart';

const String url =
    'http://ec2-3-110-172-225.ap-south-1.compute.amazonaws.com:3000/fan/sendOTP';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Future<void> _sendOTP(BuildContext context) async {
    Map<String, String> reqBody = {
      'email': widget.email,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(reqBody),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, navigate to the home screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
                email: widget.email), // Adjust as necessary
          ),
        );
      } else {
        // If the server did not return a 200 OK response, show an error message
        _showErrorDialog(context);
      }
    } catch (e) {
      // If there was an error during the HTTP request, show an error message
      _showErrorDialog(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Confirm Email',
                style: GoogleFonts.readexPro(
                  fontSize: 40.0,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFF4F5FC),
                ),
              ),
              Text(
                'Are you sure this is your email?',
                style: GoogleFonts.readexPro(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFF4F5FC),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: const BorderRadius.all(Radius.circular(8))),
                child: Text(
                  widget.email,
                  style: GoogleFonts.readexPro(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF4F5FC),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _sendOTP(context);
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
                    'Yes. Send OTP',
                    style: GoogleFonts.readexPro(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF171c2e),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
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
                    'No. Go back.',
                    style: GoogleFonts.readexPro(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF171c2e),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
