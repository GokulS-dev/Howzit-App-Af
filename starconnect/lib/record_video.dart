import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';

final filter = ProfanityFilter();
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

class RecordVideo extends StatefulWidget {
  final String fanName;
  final String celebName;
  final String wishesTo;
  final String occasion;
  final String additionalInfo;
  final int orderId;

  const RecordVideo({
    Key? key,
    required this.fanName,
    required this.celebName,
    required this.wishesTo,
    required this.occasion,
    required this.additionalInfo,
    required this.orderId,
  }) : super(key: key);

  @override
  State<RecordVideo> createState() => _RecordVideoState();
}

class _RecordVideoState extends State<RecordVideo> {
  bool _isLoading = false;
  String? _filePath;
  TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Video', style: GoogleFonts.readexPro()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => _buildChooseVideoSourceDialog(),
          );
        },
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildUI(),
      ),
    );
  }

  Widget _buildUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            SizedBox(height: 20),
            _buildDetailsBox(),
            SizedBox(height: 20),
            TextFormField(

              controller: descriptionController,
              style: GoogleFonts.readexPro(
              ),
              decoration: InputDecoration(
                labelText: 'Description',
              ).applyDefaults(Theme.of(context).inputDecorationTheme),
            ),
            SizedBox(height: 20),
        if (_filePath != null) ...[

    SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadVideo,
                child: _isLoading
                    ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.secondary,
                  ),
                )
                    :Text('Upload', style: GoogleFonts.readexPro(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: const Color(0xFF171c2e),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
    ]
          ],

      ),
    );
  }

  Widget _buildDetailsBox() {
    return Container(
      width: double.infinity, // Take the entire width of the screen
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, ), // Dotted border
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Details',
              style: GoogleFonts.readexPro(
                  textStyle: TextStyle(
                      fontSize: 30

                  )
              ),

            ),
          ),
          SizedBox(height: 16),
          _buildDetailItem('Wishes To:', widget.wishesTo),
          _buildDetailItem('Occasion:', widget.occasion),
          _buildDetailItem('Additional Info:', widget.additionalInfo),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.readexPro(
            textStyle: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.readexPro(
            textStyle: TextStyle(
              fontSize: 15,
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildChooseVideoSourceDialog() {
    return AlertDialog(
        title: Text('Choose Video Source', style: GoogleFonts.readexPro(),),
        content:          ListTile(
          leading: Icon(Icons.folder),
          title: Text('Pick from Gallery', style: GoogleFonts.readexPro(
          )),
          onTap: () {
            Navigator.pop(context);
            _pickVideo();
          },
        )
//       Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         // ListTile(
//         //   leading: Icon(Icons.camera_alt),
//         //   title: Text('Record Video'),
      //   onTap: () {
      //     Navigator.pop(context);
      //     _recordVideo();
      //   },
      // ),
      // children: [
      //   ListTile(
      //     leading: Icon(Icons.folder),
      //     title: Text('Pick from Gallery'),
      //     onTap: () {
      //       Navigator.pop(context);
      //       _pickVideo();
      //     },
      //   ),
      // ],
    );
  }

  Future<bool> _requestPermission(Permission permission) async {
    var result = await permission.request();
    if (await permission.isGranted) {
      return true;
    } else {
      return result == PermissionStatus.granted;
    }
  }


  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowCompression: true,
    );
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path!;
      });

    }

  }

  Future<void> _recordVideo() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordCameraScreen(camera: frontCamera),
      ),
    ).then((recordedFilePath) {
      if (recordedFilePath != null) {
        setState(() {
          _filePath = recordedFilePath;
        });
      }
    });
  }

  Future<void> _uploadVideo() async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });
    String? token = await readValue();
    String? baseurl = dotenv.env['URL'];

    if (_filePath == null) {
      return; // No video to upload
    }
    if (filter.hasProfanity(descriptionController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Description contains inappropriate language.', style: GoogleFonts.readexPro(
          )),
        ),
      );
      setState(() {
        _isLoading = false; // Set loading state to false
      });
      return; // Exit the method
    }
    try {
      final url = Uri.parse('$baseurl/videos');
      final request = http.MultipartRequest('POST', url);

      // Attach the video file
      request.files.add(await http.MultipartFile.fromPath(
        'video',
        _filePath!,
        contentType: MediaType('video', 'mp4'),
      ));

      // Attach other form data
      request.fields['orderid'] = widget.orderId.toString();
      request.fields['celeb_username'] = widget.celebName;
      request.fields['fan_username'] = widget.fanName;
      request.fields['description'] = descriptionController.text;
      request.headers['Authorization'] = "Bearer $token";

      // Logging the final URL
      print('Final URL: ${request.url}');

      // Logging request headers
      print('Request Headers:');
      request.headers.forEach((key, value) {
        print('$key: $value');
      });

      // Logging request body (fields and files)
      print('Request Body:');
      request.fields.forEach((key, value) {
        print('$key: $value');
      });
      request.files.forEach((file) {
        print('File: ${file.filename}, Size: ${file.length} bytes');
      });

      final response = await request.send();

      // Logging response
      final responseHeaders = response.headers.map;
      final responseBody = await response.stream.bytesToString();
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('$key: $value');
      });
      print('Response Body:');
      print(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successful upload
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text('Video uploaded successfully!', style: GoogleFonts.readexPro(
                color: Colors.white
            ),),
          ),
        );
      } else {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('Failed to upload video. Please try again later', style: GoogleFonts.readexPro(
                color: Colors.white
            ),),
          ),
        );
      }
    } catch (e) {
      print('Error uploading video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Upload exception. Try again later.', style: GoogleFonts.readexPro(
              color: Colors.white
          ),),
        ),
      );
    }
    finally{
      setState(() {
        _isLoading = false; // Set loading state to false
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class RecordCameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const RecordCameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _RecordCameraScreenState createState() => _RecordCameraScreenState();
}

class _RecordCameraScreenState extends State<RecordCameraScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Video'),
      ),
      body: SingleChildScrollView(child: _buildDetailsBox()),
    );
  }

  Widget _buildDetailsBox() {
    return Container(
      width: double.infinity, // Take the entire width of the screen
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, ), // Dotted border
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Details',
              style: GoogleFonts.readexPro(
                  textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 30

                  )
              ),

            ),
          ),
          SizedBox(height: 16),
          Text('Camera is here'),
          _buildDetailItem('Wishes To:', 'Replace with data source'),
          _buildDetailItem('Occasion:', 'Replace with data source'),
          _buildDetailItem('Additional Info:', 'Replace with data source'),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.readexPro(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.readexPro(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildChooseVideoSourceDialog() {
    return AlertDialog(
        title: Text('Choose Video Source', style: GoogleFonts.readexPro(color: Colors.white),),
        content:          ListTile(
          leading: Icon(Icons.folder, color: Colors.white,),
          title: Text('Pick from Gallery', style: GoogleFonts.readexPro(
              color: Colors.white
          )),
          onTap: () {
            Navigator.pop(context);
            _pickVideo();
          },
        )
//       Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         // ListTile(
//         //   leading: Icon(Icons.camera_alt),
//         //   title: Text('Record Video'),
//         //   onTap: () {
//         //     Navigator.pop(context);
//         //     _recordVideo();
//         //   },
//         // ),
//         children: [
//
// ,
//         ],
//       ),
    );
  }

  Future<bool> _requestPermission(Permission permission) async {
    var result = await permission.request();
    if (await permission.isGranted) {
      return true;
    } else {
      return result == PermissionStatus.granted;
    }
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowCompression: true,
    );
    if (result != null) {
      setState(() {
        //_filePath = result.files.single.path!;
      });
    }
  }

  Future<void> _recordVideo() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordCameraScreen(camera: frontCamera),
      ),
    ).then((recordedFilePath) {
      if (recordedFilePath != null) {
        setState(() {
          //_filePath = recordedFilePath;
        });
      }
    });
  }

}
