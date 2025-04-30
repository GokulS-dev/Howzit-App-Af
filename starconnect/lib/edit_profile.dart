import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:star_connectz/login_screen.dart';

final FlutterSecureStorage _storage = FlutterSecureStorage();
Future<String?> readValue() async {
  String? value = await _storage.read(key: 'token');
  if (value != null) {
    print('Stored value: $value');
  } else {
    print('No value found');
  }
  return value;
}

String? url = dotenv.env['URL'];

class EditProfile extends StatefulWidget {
  final String username;
  const EditProfile({Key? key, required this.username}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController _socialsController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _socialsController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile',
        style: GoogleFonts.readexPro(),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                style: GoogleFonts.readexPro(
                ),
                decoration: InputDecoration(
                  labelText: 'Username',
                ).applyDefaults(Theme.of(context).inputDecorationTheme),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: GoogleFonts.readexPro(
                ),
                decoration: InputDecoration(
                  labelText: 'Email',
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _socialsController,
                style: GoogleFonts.readexPro(
                ),
                decoration: InputDecoration(
                  labelText: 'Socials',
                 ).applyDefaults(Theme.of(context).inputDecorationTheme),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _saveProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save',
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

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      String username = _usernameController.text;
      String email = _emailController.text;
      String socials = _socialsController.text;

      // Replace with your update logic (e.g., API call)
      _updateProfile(username, email, socials);
    }
  }
  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(
            'Success',
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '$message',
            style: GoogleFonts.readexPro(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: GoogleFonts.readexPro(),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  void _updateProfile(String username, String email, String socials) async {
    String endpoint = '$url/celeb/${widget.username}'; // Replace with your API endpoint
    String? token = await readValue();
    Map<String, dynamic> requestBody = {
      'username': username,
      'email': email,
      'socials': socials,
      // Add other fields as needed
    };

    try {
      // Convert request body to JSON for logging
      String requestBodyJson = jsonEncode(requestBody);
      print('Request Body: $requestBodyJson');

      final requestHeaders = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': "Bearer $token",
      };

      // Make the PATCH request
      final response = await http.patch(
        Uri.parse(endpoint),
        headers: requestHeaders,
        body: requestBodyJson,
      );

      // Logging request headers (since request object is not directly accessible after sending)
      print('Request Headers: $requestHeaders');

      // Logging response headers and body
      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showDialog(context, responseData['message']);
        // Optionally navigate back or handle success action
      } else {
ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              responseData['message']!,
              style: GoogleFonts.readexPro(
                color: Colors.white,
              ),
            ),
          ),
        );

      }
    } catch (e) {
      print('Error: $e');
      // Handle network error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegExp = RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
}
