import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:star_connectz/onboarding.dart';
import 'sign_up.dart';
import 'bottom_navbar_celeb.dart';
import 'bottom_navbar_fan.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';

String? url = dotenv.env['URL'];

class AuthScreenSignUp extends StatefulWidget {
  const AuthScreenSignUp({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreenSignUp> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  String userName = 'User';
  bool _isCelebrity = false;
  bool _showSocials = true;
  bool _obscureText = true;
  bool _isLoading = false;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: Text(
            'Log in Failed',
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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });
    String endpoint = "$url/auth/login";
    String type = "";
    if(_isCelebrity == true){
      type = "celeb";
    }
    else{
      type = "fan";
    }
    Map<String, String> reqBody = {
      "username": usernameController.text,
      "password": passwordController.text,
      "type": type
    };
    print("request Body: $reqBody");
    print("URL: $endpoint");

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
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String token = data['accessToken'];

        // If the server returns a 200 OK response, navigate to the home screen
        if (_isCelebrity) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OnboardingScreen(username: usernameController.text),
              ));
          await _storage.write(key: 'token', value: token.toString());
          print(data['id']);
          print(data['accessToken']);
        } else {
          // Extract the celebId from the response
          // Save the celebId using flutter_secure_storage

          final int userId = data['id'];
          final String token = data['accessToken'];
          await _storage.write(key: 'userId', value: userId.toString());
          await _storage.write(key: 'token', value: token.toString());

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavigationBarWidgetFan(
                  username: usernameController.text, userid: data['userId']),
            ),
          );
        }
      } else {
        _showErrorDialog(context, data['message']);
        // Handle login error
        print('Failed to login');
      }
    } catch (e) {
      // Handle login error
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false
      });
    }

  }

  void signUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.5, // Adjust opacity for desired visibility (0.0 - invisible, 1.0 - fully visible)
                  child: Image.asset(
                    'assets/appsignupbg.jpg', // Replace with your background image path
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              height: 150, // You can adjust the height and width as needed
                              width: 700,
                            ),
                            Text(
                              'Login',
                              style: GoogleFonts.readexPro(
                                fontSize: 40.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: usernameController,
                              style: GoogleFonts.readexPro(
                              ),
                              decoration: InputDecoration(
                                labelText: 'Username',
                              ).applyDefaults(Theme.of(context).inputDecorationTheme),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              obscureText: _obscureText,
                              controller: passwordController,
                              style: GoogleFonts.readexPro(
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',

                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                              ).applyDefaults(Theme.of(context).inputDecorationTheme),

                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              title: Text(
                                'Are you a celebrity?',
                                style: GoogleFonts.readexPro(
                                ),
                              ),
                              value: _isCelebrity,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isCelebrity = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : login,
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
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                )
                                    : Text(
                                  'Login',
                                  style: GoogleFonts.readexPro(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(thickness: 1),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: [
                                  Text(
                                    'Don\'t have an account?',
                                    style: GoogleFonts.readexPro(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: signUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                        foregroundColor: const Color(0xFF171c2e),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: GoogleFonts.readexPro(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]
        )
    );

  }
}
