import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

// Import all your screen files
import 'login_screen.dart';
import 'sign_up.dart';
import 'home_screen.dart';
import 'request_video_screen.dart';
import 'order_history_screen_celeb.dart';
import 'celebrity_details_screen.dart';
import 'celeb_onboarding_details.dart';
import 'profile_picture.dart';
import 'profile_screen.dart';
import 'login_screen_after_signup.dart';
import 'personal_time_celeb.dart';
import 'personal_time_fan.dart';
import 'booking_screen.dart';
import 'record_audio.dart';


late final StreamVideo client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  String? apiUrl = dotenv.env['API_URL'];

  if (apiUrl != null) {
    print('API URL: $apiUrl');
  } else {
    print('❌ API_URL not found in .env file');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme(
        primary: const Color(0xFFFF6F00),
        primaryContainer: const Color(0xFFFFA040),
        secondary: const Color(0xFFFF6F00),
        secondaryContainer: const Color(0xFF424242),
        surface: const Color(0xFFF5F5F5),
        background: const Color(0xFFFFFFFF),
        error: const Color(0xFFC62828),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.black,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.readexProTextTheme().apply(bodyColor: Colors.black),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFF6F00),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      cardColor: const Color(0xFFFFA040),
      iconTheme: const IconThemeData(color: Color(0xFFFF6F00)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFFFF6F00),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF6F00)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
        labelStyle: GoogleFonts.readexPro(color: Colors.black),
        hintStyle: const TextStyle(color: Colors.black),
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      ),
    );

    return GetMaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AuthScreen(),
        '/loginSignUp': (context) => const AuthScreenSignUp(),
        '/signup': (context) => const SignUpScreen(),
        '/requestVideo': (context) => const RequestVideoScreen(),
        '/orderHistory': (context) => const OrderHistoryScreenCeleb(username: 'toto'),
        '/onboardingDetails': (context) => const CelebrityProfileScreen(username: ''),
        '/profile': (context) => ProfileScreen(jsonString: '{...}'), // Replace with real data
        '/profilePicture': (context) => const ProfilePictureUploadScreen(username: 'Steiner'),
      },
    );
  }
}