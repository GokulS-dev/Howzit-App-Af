import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key});

  final List<String> services = const [
    'Birthday Wish',
    'Anniversary Wish',
    'Customised Greeting',
    'Congratulate on Wedding',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Available Services',
          style: GoogleFonts.readexPro(
            color: const Color(0xFFF4F5FC),
          ),
        ),
        backgroundColor: const Color(0xFF171c2e),
      ),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              services[index],
              style: GoogleFonts.readexPro(
                color: const Color(0xFFF4F5FC),
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Return to the previous screen
            },
          );
        },
      ),
    );
  }
}
