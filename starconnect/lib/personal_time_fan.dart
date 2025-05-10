import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;



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
class PersonalTimeFanPage extends StatefulWidget {
  final int orderId;
  const PersonalTimeFanPage({
    Key? key,
    required this.orderId
  }) : super(key: key);

  @override
  _PersonalTimePageState createState() => _PersonalTimePageState();
}

class _PersonalTimePageState extends State<PersonalTimeFanPage> {
  bool _isLoading = false;
  bool _isCameraInitialized = false;
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[1], ResolutionPreset.medium);
    await _controller.initialize();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isCameraInitialized = true;
    });  }


  Future<void> _joinCall() async {
    setState(() {
      _isLoading = true;
// Set loading state to true
    });
    _controller.dispose();

    try {

      String? url = dotenv.env['URL'];
      String? token = await readValue();
      String? endpoint = "$url/meeting/getMeeting/${widget.orderId}";
      // Prepare the request body

      Map<String,String> requestHeaders =  {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      // Send POST request
      final response = await http.get(
        Uri.parse(endpoint),
        headers: requestHeaders,
      );

      // Print request and response details
      print('Request Headers: $requestHeaders');
      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print("Video call Response Data: $responseData");
        print('Celeb token: ${responseData['order']['celeb_token']}'); // Print the celeb token

        final guest = User.guest(userId: responseData['order']['fan_username'], name: responseData['order']['fan_username']);
        // Initialize the StreamVideo client
        StreamVideo.reset();
        final client = StreamVideo(
            '4e7xphj2343z',
            user: guest
        );
        var call = client.makeCall(
          callType: StreamCallType(),
          id: responseData['order']['call_id'],
        );

        await call.join();
        Navigator.pop(context);
        // Handle successful response
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(call: call),
          ),
        );
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
        // Handle error response
        print('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error joining or creating call: $e');
      debugPrint(e.toString());
    }
    finally {
      setState(() {
        _isLoading = false; // Set loading state to false
      });
    }

  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_isCameraInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Personal Time',
          style: GoogleFonts.readexPro(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controller != null && _controller.value.isInitialized
                  ? Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12)
                ),
                width: double.infinity,
                height: 500,
                child: AspectRatio(aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller)),
              )
                  : Container(),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _joinCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: const Color(0xFF171c2e),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                    'Join Call',
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
      ),
    );
  }
}

class CallScreen extends StatefulWidget {
  final Call call;

  const CallScreen({Key? key, required this.call}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamCallContainer(
          call: widget.call,
        ));
  }
}
