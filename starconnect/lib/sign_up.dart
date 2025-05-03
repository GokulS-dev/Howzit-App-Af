import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:star_connectz/login_screen_after_signup.dart';
import 'package:star_connectz/onboarding.dart';
import 'package:country_picker_pro/country_picker_pro.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'celeb_onboarding_details.dart';

String? apiUrl = dotenv.env['API_URL'];

class SignUpControllers {
  static final TextEditingController nameController = TextEditingController();
  static final TextEditingController emailController = TextEditingController();
  static final TextEditingController passwordController =
      TextEditingController();
  static final TextEditingController socialsController =
      TextEditingController();
  static final TextEditingController phoneNumberController =
      TextEditingController();
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCelebrity = false;
  bool _showSocials = false;
  bool _obscureText = true;
  String? _selectedCountry;
  final List<String> _countries = ['Zimbabwe', 'Zambia'];

  Future<void> _signUp(BuildContext context, String username) async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });
    String countryCode = _selectedCountry == "Zambia" ? "ZM" : "ZW";
    if (_formKey.currentState?.validate() ?? false) {
      final String name = SignUpControllers.nameController.text;
      final String email = SignUpControllers.emailController.text;
      final String password = SignUpControllers.passwordController.text;
      final String socials = SignUpControllers.socialsController.text;
      final String phone = SignUpControllers.phoneNumberController.text;

      String endpoint = _isCelebrity ? "$apiUrl/celeb" : "$apiUrl/fan";

      Map<String, String> reqBody = _isCelebrity
          ? {
              'username': name,
              'email': email,
              'password': password,
              'bio': 'My bio',
              'socials': socials,
              'country': countryCode,

            }
          : {
              'username': name,
              'email': email,
              'password': password,
              'phone': phone,
              'country': countryCode,

      };

      print("Request Body: $reqBody");
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
          if (_isCelebrity) {
            // If the server returns a 200 OK response, navigate to the home screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuthScreenSignUp(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuthScreen(),
              ),
            );
          }
        } else {
          // If the server did not return a 200 OK response, show an error dialog
          _showErrorDialog(context, data['message']);
        }
      } catch (e) {
        // If there was an error during the HTTP request, show an error dialog
        print('Error: $e');
      } finally {
        setState(() {
          _isLoading = false; // Set loading state to false
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Sign Up Failed',
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Positioned.fill(
        child: Opacity(
          opacity:
              0.5, // Adjust opacity for desired visibility (0.0 - invisible, 1.0 - fully visible)
          child: Image.asset(
            'assets/appsignupbg.jpg', // Replace with your background image path
            fit: BoxFit.cover,
          ),
        ),
      ),
      Center(
          child: Form(
        key: _formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Sign Up',
                    style: GoogleFonts.readexPro(
                      fontSize: 40.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: SignUpControllers.nameController,
                    style: GoogleFonts.readexPro(),
                    decoration: InputDecoration(
                      labelText: 'Username',
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.contains(RegExp(r'[A-Z]'))) {
                        return 'Please do not use capital letters';
                      }
                      if (value.contains(' ')) {
                        return 'Please do not use spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: SignUpControllers.emailController,
                    style: GoogleFonts.readexPro(),
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: SignUpControllers.passwordController,
                    style: GoogleFonts.readexPro(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    obscureText: _obscureText,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  _showSocials
                      ? TextFormField(
                          controller: SignUpControllers.socialsController,
                          style: GoogleFonts.readexPro(),
                          decoration: InputDecoration(
                            labelText: 'Instagram Handle',
                          ).applyDefaults(
                              Theme.of(context).inputDecorationTheme),
                        )
                      : TextFormField(
                          controller: SignUpControllers.phoneNumberController,
                          style: GoogleFonts.readexPro(),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                          ).applyDefaults(
                              Theme.of(context).inputDecorationTheme),
                        ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    items: _countries.map((String country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country, style: GoogleFonts.readexPro()),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Country',
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCountry = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your country';
                      }
                      return null;
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Are you a celebrity?',
                      style: GoogleFonts.readexPro(),
                    ),
                    value: _isCelebrity,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCelebrity = value ?? false;
                        if (_isCelebrity) {
                          _showSocials = true;
                        } else {
                          _showSocials = false;
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _isLoading
                            ? null
                            : _signUp(
                                context, SignUpControllers.nameController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
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
                              'Sign Up',
                              style: GoogleFonts.readexPro(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
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
      )),
    ]));
  }
}
