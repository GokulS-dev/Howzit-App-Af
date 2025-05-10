import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:star_connectz/login_screen.dart';
import 'create_post.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
String endpoint = (apiurl ?? 'https://your-default-api.com') + '/celeb/updateProfilePic';



class ProfilePictureUploadScreen extends StatefulWidget {
  final String username;
  const ProfilePictureUploadScreen({Key? key, required this.username}) : super(key: key);

  @override
  _ProfilePictureUploadScreenState createState() =>
      _ProfilePictureUploadScreenState();
}

class _ProfilePictureUploadScreenState
    extends State<ProfilePictureUploadScreen> {
  bool _isLoading = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      // File rotatedImage = await FlutterExifRotation.rotateImage(path: pickedFile.path);
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            'Success',
            style: GoogleFonts.readexPro(
              color: Colors.red,
            ),
          ),
          content: Text(
            'Your account has been created successfully!',
            style: GoogleFonts.readexPro(
              color: Colors.red
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuthScreen(),
                  ),
                );
              },
              child: Text(
                'OK',
                style: GoogleFonts.readexPro(
                  color: const Color(0xFF8EBBFF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  Future<void> _uploadProfilePicture() async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });
    String? token = await readValue(); // Await here to get the actual token
    if (_image != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(endpoint),
      );
      request.fields['username'] = widget.username;
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
      print("URL: $endpoint");
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
        print('Response Body: $responseData');
        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSuccessDialog();
          final responseData = await response.stream.bytesToString();
          print('Response Data: $response');
          

          // Handle success (e.g., show a success message or navigate)
        } else {
          print('Upload failed with status: $response');
          // Handle failure (e.g., show an error message)
        }
      } catch (e) {
        print('Upload failed with error: $e');
        // Handle error (e.g., show an error message)
      }
      finally{
        setState(() {
          _isLoading = false; // Set loading state to false
        });
      }
    } else {
      print('No image selected');
      // Show a message to select an image
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Profile Picture',
          style: GoogleFonts.readexPro(
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Profile Picture',
                style: GoogleFonts.readexPro(
                  fontSize: 40.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _image != null
                  ? CircleAvatar(
                      radius: 80,
                      backgroundImage: FileImage(_image!),
                    )
                  :  CircleAvatar(
                      radius: 80,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.black,
                      ),
                    ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(

                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.readexPro(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Take a Photo',
                    style: GoogleFonts.readexPro(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploadProfilePicture,
                  style: ElevatedButton.styleFrom(

                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
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
                    'Upload Profile Picture',
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
    );
  }
}
