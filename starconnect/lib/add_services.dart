import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'profile_picture.dart';
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


String? apiurl = dotenv.env['API_URL'];
String endpoint = (apiurl ?? '') + '/service';

class ServiceController {
  final TextEditingController amountController;
  final TextEditingController timeNeededController;
  final TextEditingController categoryController;
  String? selectedService;

  ServiceController()
      : amountController = TextEditingController(),
        timeNeededController = TextEditingController(text: '2'),
        categoryController = TextEditingController();
}

class AddServices extends StatefulWidget {
  final String username;
  const AddServices({Key? key, required this.username}) : super(key: key);

  @override
  _CelebrityProfileScreenState createState() => _CelebrityProfileScreenState();
}

class _CelebrityProfileScreenState extends State<AddServices> {
  final List<String> _availableServices = [
    'Video Message',
    'Audio Message',
    'Personal Time',
  ];

  final List<String> _profileTypes = [
    'Personal',
    'Business',
  ];

  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _bioController = TextEditingController();
  List<ServiceController> _serviceControllers = [];
  int _currentServiceIndex = 0;

  int numberOfServices = 1; // Default number of services
  String? _selectedProfileType;

  @override
  void initState() {
    super.initState();
    _serviceControllers =
        List.generate(numberOfServices, (_) => ServiceController());
  }

  void _submitProfile(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final String bio = _bioController.text;
      final List<Map<String, dynamic>> services = _serviceControllers.map((controller) {
        return {
          'price': int.parse(controller.amountController.text),
          'description': controller.selectedService,
          'time_needed': int.parse(controller.timeNeededController.text),
          'category': controller.categoryController.text.toLowerCase()
        };
      }).toList();

      final Map<String, dynamic> reqBody = {
        'username': widget.username,
        'bio': bio,
        'services': services,
      };
      String? token = await readValue(); // Await here to get the actual token
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': "Bearer $token"
      };
      // Print headers for debugging
      print("Request Headers: $headers");
      print("Request Body: $reqBody");
      print("URL: $endpoint");

      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: headers,
          body: jsonEncode(reqBody),
        );

        print(response.body);
        print(response.headers);
        if (response.statusCode == 200 || response.statusCode == 201) {
          print("Uploaded Successfully");

          // Show success message and navigate to services screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              content: Text(
                'Services added successfully',
                style: GoogleFonts.readexPro(
                  color: Colors.white,
                ),
              ),
            ),
          );

          // Navigate to services screen after a short delay
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pop(context);

        } else {
          Map<String, dynamic> responseData = json.decode(response.body);
          // Show an error message
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
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
          ),
        );
      }
    }
  }

  void _nextService() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_currentServiceIndex < numberOfServices - 1) {
        setState(() {
          _currentServiceIndex++;
        });
      } else {
        _submitProfile(context);
      }
    }
  }

  void _updateNumberOfServices(String value) {
    setState(() {
      numberOfServices = int.tryParse(value) ?? 1;
      _serviceControllers =
          List.generate(numberOfServices, (_) => ServiceController());
      _currentServiceIndex = 0; // Reset current service index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Services',
          style: GoogleFonts.readexPro(
            color: const Color(0xFFF4F5FC),
          ),
        ),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Add Services',
                  style: GoogleFonts.readexPro(
                    fontSize: 40.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  value: _selectedProfileType,
                  items: _profileTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.readexPro(
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedProfileType = newValue;
                      // Update the categoryController of the current service
                      _serviceControllers[_currentServiceIndex].selectedService = newValue ?? 'defaultService';
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Profile Type',
                   ).applyDefaults(Theme.of(context).inputDecorationTheme),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a profile type';
                    }
                    _serviceControllers[_currentServiceIndex].categoryController.text = value;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: numberOfServices.toString(),
                  onChanged: _updateNumberOfServices,
                  style: GoogleFonts.readexPro(
                  ),
                  decoration: InputDecoration(
                    labelText: 'Number of Services',
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of services';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_serviceControllers.isNotEmpty)
                  TextFormField(
                    controller: _serviceControllers[_currentServiceIndex].amountController,
                    style: GoogleFonts.readexPro(
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',

                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the amount';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                if (_serviceControllers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    value: _serviceControllers[_currentServiceIndex].selectedService,
                    items: _availableServices.map((service) {
                      return DropdownMenuItem<String>(
                        value: service,
                        child: Text(
                          service,
                          style: GoogleFonts.readexPro(
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _serviceControllers[_currentServiceIndex].selectedService = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Service Type',
                     ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a service type';
                      }
                      _serviceControllers[_currentServiceIndex].selectedService = value;
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                if (_serviceControllers.isNotEmpty)
                  TextFormField(
                    controller: _serviceControllers[_currentServiceIndex].timeNeededController,
                    style: GoogleFonts.readexPro(
                    ),
                    decoration: InputDecoration(
                      labelText: 'Time Needed (hours)',
                     ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the time needed';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextService,
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
                        child: Text(
                          _currentServiceIndex < numberOfServices - 1
                              ? 'Next Service'
                              : 'Add Services',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
