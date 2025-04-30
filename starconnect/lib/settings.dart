import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:star_connectz/login_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.readexPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.readexPro(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SwitchListTile(
              title: Text('Enable Notifications',
                  style: GoogleFonts.readexPro()),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const Divider(),
            Text(
              'Appearance',
              style: GoogleFonts.readexPro(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SwitchListTile(
              title:  Text('Dark Mode', style: GoogleFonts.readexPro()),
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
            ),
            const Divider(),
// BUTTON STYLING
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (){
    Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (BuildContext context) => const AuthScreen()),
    (Route<dynamic> route) => false, // This removes all previous routes
    );

                },
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
                  'Log Out',
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
    );
  }
}
