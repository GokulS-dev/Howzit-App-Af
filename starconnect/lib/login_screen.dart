import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'sign_up.dart';
import 'bottom_navbar_celeb.dart';
import 'bottom_navbar_fan.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  bool _isCelebrity = false;
  bool _obscureText = true;
  bool _isLoading = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    // Removed dotenv.load() from here – should be in main()
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.error,
          title: Text(
            'Login Failed',
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.readexPro(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: GoogleFonts.readexPro(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> login() async {
    setState(() {
      _isLoading = true;
    });

    String? apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null || apiUrl.isEmpty) {
      setState(() => _isLoading = false);
      _showErrorDialog(context, 'API URL is not set in .env file.');
      return;
    }

    String endpoint = "$apiUrl/auth/login";
    String type = _isCelebrity ? "celeb" : "fan";

    Map<String, dynamic> reqBody = {
      "username": usernameController.text,
      "password": passwordController.text,
      "type": type,
    };

    print("Request Body: $reqBody");
    print("Calling API: $endpoint");

    try {
      final response = await http
          .post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reqBody),
      )
          .timeout(const Duration(seconds: 10));

      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final String token = data['accessToken'];
        final int userId = data['userId'];

        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'userId', value: userId.toString());
        await _storage.write(key: 'country', value: data['country']);

        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _isCelebrity
                ? BottomNavigationBarWidgetCeleb(
              username: usernameController.text,
              userId: userId,
            )
                : BottomNavigationBarWidgetFan(
              username: usernameController.text,
              userid: userId,
            ),
          ),
        );
      } else {
        final data = json.decode(response.body);
        _showErrorDialog(context, data['message'] ?? 'Login failed.');
      }
    } on TimeoutException {
      _showErrorDialog(context, 'Connection timed out. Please try again.');
    } catch (e) {
      _showErrorDialog(context, 'Something went wrong. Please try again.');
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void signUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.5,
            child: Image.asset('assets/appsignupbg.jpg', fit: BoxFit.cover),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 150),
                Text('Login',
                    style: GoogleFonts.readexPro(fontSize: 40, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: 'Username')
                      .applyDefaults(Theme.of(context).inputDecorationTheme),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() => _obscureText = !_obscureText);
                      },
                    ),
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text('Are you a celebrity?', style: GoogleFonts.readexPro()),
                  value: _isCelebrity,
                  onChanged: (value) {
                    setState(() => _isCelebrity = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : login,
                    child: _isLoading
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary),
                    )
                        : Text('Login',
                        style: GoogleFonts.readexPro(
                            fontSize: 16.0, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 20),
                Text("Don't have an account?", style: GoogleFonts.readexPro()),
                TextButton(onPressed: signUp, child: Text("Sign Up")),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}