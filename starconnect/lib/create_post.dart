import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_exif_rotation/flutter_exif_rotation.dart'; //EXIF rotation library
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String? apiurl = dotenv.env['API_URL'];
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

class CreatePostScreen extends StatefulWidget {
  final String username;

  const CreatePostScreen({Key? key, required this.username}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  String endpoint = (apiurl ?? 'https://example.com') + '/post';

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      // File rotatedImage = await FlutterExifRotation.rotateImage(path: pickedFile.path);
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_isUploading) {
      return; // Prevent multiple presses while uploading
    }

    String? token = await readValue();
    if (_image != null && _captionController.text.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(endpoint),
      );
      request.fields['celeb_username'] = widget.username;
      request.fields['caption'] = _captionController.text;
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _image!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      try {
        final response = await request.send();
        final responseData = await response.stream.bytesToString();

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Response Data: $responseData');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Uploaded successfully',
                style: GoogleFonts.readexPro(
                ),
              ),
            ),
          );
          // Clear form fields and reset state
          setState(() {
            _image = null;
            _captionController.clear();
            _isUploading = false;
          });
        } else {
          print('Upload failed with status: $responseData');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Upload failed',
                style: GoogleFonts.readexPro(
                ),
              ),
            ),
          );
          setState(() {
            _isUploading = false;
          });
        }
      } catch (e) {
        print('Upload failed with error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload failed: $e',
              style: GoogleFonts.readexPro(
              ),
            ),
          ),
        );
        setState(() {
          _isUploading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No image selected or caption is empty',
            style: GoogleFonts.readexPro(
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: GoogleFonts.readexPro(
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'New Post',
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
                    : const CircleAvatar(
                  radius: 80,
                  child: Icon(
                    Icons.image,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _captionController,
                  style: GoogleFonts.readexPro(
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter caption',
                    hintStyle: GoogleFonts.readexPro(
                    ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                    onPressed: _isUploading ? null : _uploadPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUploading
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    )
                        : Text(
                      'Upload Post',
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
  }
}
