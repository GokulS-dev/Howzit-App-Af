import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:star_connectz/edit_profile.dart';
import '../DataModels/UserProfile.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'add_services.dart';
import 'edit_profile.dart';
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
String endpoint = apiurl! + '/service/';

class ProfileScreen extends StatefulWidget {
  final String jsonString;
  const ProfileScreen({super.key, required this.jsonString});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile userProfile;

  @override
  void initState() {
    super.initState();
    userProfile = parseUserProfile(widget.jsonString);
  }

  UserProfile parseUserProfile(String jsonString) {
    final jsonResponse = json.decode(jsonString);
    print("JSON Response: $jsonResponse");
    return UserProfile.fromJson(jsonResponse);
  }

  void showServicesDialog(BuildContext context, List<Service> services) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'My Services',
            style: GoogleFonts.readexPro(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      service.description,
                      style: GoogleFonts.readexPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Amount: \$${service.price}, Status: ${service.status}',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Close',
                style: GoogleFonts.readexPro(
                ),
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

  void _addServices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddServices(username: userProfile.username)),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfile(username: userProfile.username)),
    );
  }

  Future<void> _deleteService(int serviceId) async {
    String? token = await readValue();
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    print("Endpoint: $endpoint");
    print("Service ID: $serviceId");
    String finalURL = "$endpoint$serviceId";
    final url = Uri.parse(finalURL);
    print("URL: $url");
    final response = await http.delete(url, headers: headers);
    print("Response Status Code: ${response.statusCode}");
   
    if (response.statusCode == 200) {
      setState(() {
        userProfile.services.removeWhere((service) => service.id == serviceId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Text(
            'Service deleted successfully',
            style: GoogleFonts.readexPro(
            ),
          ),
        ),
      );
    }
    else{ Map<String, dynamic> responseData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              responseData['message'],
              style: GoogleFonts.readexPro(
              ),
            ),
          ),
        );

    }
  }

  Future<void> _confirmDeleteService(int serviceId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Delete',
            style: GoogleFonts.readexPro(),
          ),
          content: Text(
            'Are you sure you want to delete this service?',
            style: GoogleFonts.readexPro(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.readexPro(),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: GoogleFonts.readexPro(),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteService(serviceId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Received JSON String: ${widget.jsonString}");
    print(userProfile);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(
            'Profile',
            style: GoogleFonts.readexPro(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                _addServices(); // Call your async function here
              },
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _editProfile(); // Call your async function here
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(userProfile.profilePicUrl),
                      ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editProfilePicture(ImageSource.gallery);
                            },
                          ),
                        ),]
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userProfile.username,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${userProfile.followers}',
                              style: GoogleFonts.readexPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Followers',
                              style: GoogleFonts.readexPro(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 30),
                        Column(
                          children: [
                            Text(
                              '${userProfile.following}',
                              style: GoogleFonts.readexPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Following',
                              style: GoogleFonts.readexPro(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                indicatorColor: Theme.of(context).colorScheme.secondary,
                tabs: [
                  Tab(
                    child: Text(
                      'Posts',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Services',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshProfile,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemCount: userProfile.posts.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                            child: Image.network(
                                              userProfile.posts[index].imageURL,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              userProfile.posts[index].caption,
                                              style: GoogleFonts.readexPro(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                Theme.of(context).colorScheme.secondary,
                                                foregroundColor: const Color(0xFF171c2e),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                'Close',
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
                                },
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  userProfile.posts[index].imageURL,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                          );
                        },
                      )

                      ,
                    ),
                    RefreshIndicator(
                      onRefresh: _refreshProfile,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(3.0),
                        itemCount: userProfile.services.length,
                        itemBuilder: (context, index) {
                          final service = userProfile.services[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              trailing: IconButton(
                                icon: Icon(Icons.delete, ),
                                onPressed: () {
                                  _confirmDeleteService(service.id);
                                },
                              ),
                              title: Text(
                                service.description,
                                style: GoogleFonts.readexPro(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Amount: \$${service.price}, Status: ${service.status}',
                                style: GoogleFonts.readexPro(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _refreshProfile() async {
    String? endpoint = '$apiurl/celeb';
    final Uri uri = Uri.parse("$endpoint/${userProfile.username}");
    String? token = await readValue();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Text(
            'Authentication token not found',
            style: GoogleFonts.readexPro(
            ),
          ),
        ),
      );
      return;
    }

    print('Fetching profile for username: ${userProfile.username}');
    print('Request URL: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );

      // Printing request headers and body
      print('Request Headers: ${response.request!.headers}');
      print("Response: $response");
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          userProfile = UserProfile.fromJson(json.decode(response.body));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              'Profile refreshed successfully',
              style: GoogleFonts.readexPro(
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              responseData['message'],
              style: GoogleFonts.readexPro(
              ),
            ),
          ),
        );

        throw Exception('Failed to refresh profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error refreshing profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Text(
            'Error refreshing profile: $e',
            style: GoogleFonts.readexPro(
            ),
          ),
        ),
      );
    }
  }


  void _editProfilePicture(ImageSource source) async{
    File? _image;
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: source);
    final editProfileEndpoint = "$apiurl/celeb/updateProfilePic";
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
    String? token = await readValue(); // Await here to get the actual token
    if (_image != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(editProfileEndpoint),
      );
      request.fields['username'] = userProfile.username;
      request.headers['Content-Type'] = 'multipart/form-data';
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _image!.path,
          contentType: MediaType('image','jpeg'),
        ),
      );

      // Printing request body to the console
      print('Request Body: $request');
      print("URL: $editProfileEndpoint");
      print('Request URL: ${request.url}');
      print('Request Method: ${request.method}');
      print('Request Headers: ${request.headers}');
      print('Request Fields: ${request.fields}');
      try {
        final response = await request.send();
        // Printing response details
        print('Response Status Code: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> responseJson = jsonDecode(responseData);
        print('Response Body: $responseData');
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              content: Text(
                responseJson['message'],
                style: GoogleFonts.readexPro(
                ),
              ),
            ),
          );

          print('Response Data: $responseData');
          // Handle success (e.g., show a success message or navigate)
        } else {
          print('Upload failed with status: $response');
          // Handle failure (e.g., show an error message)
        }
      } catch (e) {
        print('Upload failed with error: $e');
        // Handle error (e.g., show an error message)
      }
    } else {
      print('No image selected');
      // Show a message to select an image
    }
  }
  }
