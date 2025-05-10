import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_data.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:profanity_filter/profanity_filter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

final filter = ProfanityFilter();

class BookWishScreen extends StatefulWidget {
  final String celebrityName;
  final int serviceId;
  final int userId;
  final int celebid;

  const BookWishScreen({super.key, required this.celebrityName, required this.serviceId, required this.userId, required this.celebid});

  @override
  _BookWishScreenState createState() => _BookWishScreenState();
}

class _BookWishScreenState extends State<BookWishScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _wishesToController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  Future<void> bookService(int serviceId, int userId, int celebid) async {
    String? apiurl = dotenv.env['API_URL'];
    String ordersEndpoint = "$apiurl/order";
    String? token = await readValue();
    Map<String, dynamic> requestBody = {

      'serviceid': serviceId,
      'fanid': userId,
      'celebid': celebid,
    };
    print('Request Body Place Order: $requestBody');
    print('Orders Endpoint Place Order: $ordersEndpoint');
    try {
      final response = await http.post(
        Uri.parse(ordersEndpoint),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Decode the JSON response
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print("JSON Response Booking Service : $jsonResponse");
        // Extract order_id from jsonResponse
        int orderId = jsonResponse['order']['id'];
        _placeOrder(orderId);
        print('Redirecting to booking details page! Order ID: $orderId');

      } else {
        Map<String, dynamic> responseData = json.decode(response.body);
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
        throw Exception('Failed to book service: ${response.statusCode}');
      }

      print('Response Body Place Order: ${response.body}');
    } catch (e) {
      print('Error booking service: $e');
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate = DateTime.now().add(const Duration(days: 3));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate,
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = "${picked.month}/${picked.day}/${picked.year}";
      });
    }
  }
  Future<void> _placeOrder(int orderId) async {
    String? url = dotenv.env['URL'];
    String? token = await readValue();
    // Extract data from text controllers
    String occasion = _occasionController.text.trim();
    String wishesTo = _wishesToController.text.trim();
    String details = _detailsController.text.trim();

    // Construct the URL with orderId
    String endpoint = '$url/order/addDetails/${orderId}';

    // Prepare the request body
    Map<String, dynamic> requestBody = {
      'occasion': occasion,
      'wishes_to': wishesTo,
      'additional_info': details,
    };

    // Encode the request body to JSON
    String body = jsonEncode(requestBody);

    // Set up headers (if needed)
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
      // Add any additional headers as needed
    };

    try {
      // Perform the HTTP POST request
      http.Response response = await http.post(Uri.parse(endpoint), headers: headers, body: body);

      // Print request details
      print('Request URL: $endpoint');
      print('Request Body: $body');
      print('Request Headers: $headers');

      // Print response details
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');
      // Handle response based on status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        // Handle success (e.g., show success message, navigate to next screen)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              'Details added successfully!',
              style: GoogleFonts.readexPro(
                color: Colors.white,
              ),
            ),
          ),
        );

        Navigator.pop(context);


      } else {
        Map<String, dynamic> responseData = json.decode(response.body);

        // Handle errors (e.g., show error message)
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
      }
    } catch (e) {
      // Handle network errors or exceptions
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            'An error occurred. Please check your internet connection and try again.',
            style: GoogleFonts.readexPro(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _occasionController.dispose();
    _dateController.dispose();
    _wishesToController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Book a wish',
          style: GoogleFonts.readexPro(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 8),
                      Text(
                        'Share details that will help the celebrity make the perfect wish',
                        style: GoogleFonts.readexPro(
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _occasionController,
                        label: 'Occasion',
                        hintText: 'Birthday, Anniversary, etc.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _dateController,
                        label: 'Date',
                        hintText: 'MM/DD/YYYY',
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _wishesToController,
                        label: 'Wishes to',
                        hintText: 'Name of the person',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _detailsController,
                        label: 'Details',
                        hintText: 'Details for the wish',
                        maxLines: 5,
                        isDetailsField: true,
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();  // Dismiss the keyboard
                  if (_formKey.currentState!.validate()) {
                    await bookService(widget.serviceId, widget.userId, widget.celebid);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Book now',
                    style: GoogleFonts.readexPro(fontSize: 16.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    IconData? icon,
    bool isDetailsField = false,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.readexPro(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.readexPro(),
        errorStyle: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.error),
        hintText: hintText,
        hintStyle: GoogleFonts.readexPro(),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: icon != null
            ? IconButton(
          icon: Icon(icon, color: Colors.white70),
          onPressed: () {
            if (label == 'Date') {
              _selectDate(context);
            }
          },
        )
            : null,
      ),
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }

        if (isDetailsField) {
          bool hasProfanity = filter.hasProfanity(value);
          if (hasProfanity) {
            return 'Profanity detected. Please rephrase.';
          }
        }
        return null;
      },
      onTap: () {
        if (label == 'Date') {
          _selectDate(context);
        }
      },
      readOnly: label == 'Date',
    );
  }
}

