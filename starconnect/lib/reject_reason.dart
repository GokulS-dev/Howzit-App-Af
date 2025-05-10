import 'dart:convert';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final FlutterSecureStorage _storage = FlutterSecureStorage();
final filter = ProfanityFilter();

Future<String?> readValue() async {
  String? value = await _storage.read(key: 'token');
  if (value != null) {
    print('Stored value: $value');
  } else {
    print('No value found');
  }
  return value;
}

class RejectReason extends StatefulWidget {
  final int orderid;
  const RejectReason({super.key, required this.orderid});

  @override
  State<RejectReason> createState() => _RejectReasonState();
}

class _RejectReasonState extends State<RejectReason> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReason() async {
    setState(() {
      _isSubmitting = true;
    });
    if (filter.hasProfanity(_reasonController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Reason contains inappropriate language.', style: GoogleFonts.readexPro(
          )),
        ),
      );
      setState(() {
        _isSubmitting = false; // Set loading state to false
      });
      return; // Exit the method
    }
    final reason = _reasonController.text;
    String? token = await readValue();
    String? url = dotenv.env['URL'];
    String rejectReasonEndpoint = "$url/order/rejectReason/${widget.orderid}";
    print(rejectReasonEndpoint);
    Map<String, String> reqHeader = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };
    Map<String, String> requestBody = {
      "reason": reason // Update status to "rejected"
    };

    try {
      final response = await http.patch(
        Uri.parse(rejectReasonEndpoint),
        headers: reqHeader,
        body: json.encode(requestBody),
      );
      print("URL: ${rejectReasonEndpoint}");

      print("Request Headers: ${reqHeader}");
      print("Request Body: ${requestBody}");
      print("Response Headers: ${response.headers}");
      print("Response Body: ${response.body}");
      Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        // Update local state or handle success as needed
        print("Order reason uploaded successfully");
        print('Submitted Reason: $reason');
        await _rejectOrder(widget.orderid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Failed to submit reason.',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred. Please check your internet connection and try again.',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }

    // Handle the submitted reason (e.g., send to a backend or process it)
  }


  Future<void> _rejectOrder(int id) async {
    String? token = await readValue();
    String? url = dotenv.env['URL'];
    String orderEndpoint = "$url/order/$id";
    Map<String, String> reqHeader = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };
    Map<String, String> requestBody = {
      "status": "rejected" // Update status to "rejected"
    };

    try {
      // Print request headers and body
      print("Request Headers: $reqHeader");
      print("Request Body: ${json.encode(requestBody)}");

      final response = await http.patch(
        Uri.parse(orderEndpoint),
        headers: reqHeader,
        body: json.encode(requestBody),
      );

      // Print response headers and body
      print("Response Headers: ${response.headers}");
      print("Response Body: ${response.body}");
      Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              responseData['message'],
              style: GoogleFonts.readexPro(
              ),
            ),
          ),
        );
        Navigator.pop(context);
        // Update local state or handle success as needed
        print("Order $id rejected successfully");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              responseData['message'],
              style: GoogleFonts.readexPro(
                color: Colors.white,
              ),
            ),
          ),
        );

        throw Exception('Failed to reject order $id');
      }
    } catch (e) {
      print('Error rejecting order $id: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Rejection Reason',
          style: GoogleFonts.readexPro(
            color: const Color(0xFFF4F5FC),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: _reasonController,
                  style: GoogleFonts.readexPro(
                  ),
                  decoration: InputDecoration(
                    labelText: 'Reason',
                   ).applyDefaults(Theme.of(context).inputDecorationTheme),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:() async {
                      _isSubmitting ? null :  await _submitReason();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: const Color(0xFF171c2e),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    )
                        : Text(
                      'Reject',
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
        ),
      ),
    );
  }}
