import 'package:flutter/material.dart';

class RequestVideoScreen extends StatelessWidget {
  const RequestVideoScreen({super.key});

  void processPayment() {
    // Replace with actual payment processing logic
    print('Payment processed');
  }

  @override
  Widget build(BuildContext context) {
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Video Message')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Message Details'),
            ),
            ElevatedButton(
              onPressed: processPayment,
              child: const Text('Pay & Request'),
            ),
          ],
        ),
      ),
    );
  }
}
