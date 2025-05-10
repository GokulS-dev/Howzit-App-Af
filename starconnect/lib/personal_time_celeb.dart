import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:camera/camera.dart';
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

String generateRandomCallId() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  final rand = Random();
  return List.generate(12, (index) => chars[rand.nextInt(chars.length)]).join();
}

class PersonalTimeCelebPage extends StatefulWidget {
  final String celebUsername;
  final int celebId;
  final String fanUsername;
  final int fanId;
  final int orderId;
  final String wishesTo;
  final String occasion;
  final String additionalInfo;

  const PersonalTimeCelebPage({
    Key? key,
    required this.celebUsername,
    required this.celebId,
    required this.fanUsername,
    required this.fanId,
    required this.orderId,
    required this.wishesTo,
    required this.occasion,
    required this.additionalInfo,

  }) : super(key: key);

  @override
  _PersonalTimePageState createState() => _PersonalTimePageState();
}

class _PersonalTimePageState extends State<PersonalTimeCelebPage> {
  late final StreamVideo client;
  bool _isLoading = false;
  bool _isCameraInitialized = false;
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _patchStatus(String status) async {
    try {
      String? token = await readValue();
      String? url = dotenv.env['URL'];
      String orderEndpoint = "$url/order/${widget.orderId}";
      Map<String, String> reqHeader = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };
      Map<String, String> requestBody = {
        "status": status, // Update status to the provided status
      };
      print("Request Headers: $reqHeader");
      print("Request Body: ${json.encode(requestBody)}");

      final response = await http.patch(
        Uri.parse(orderEndpoint),
        headers: reqHeader,
        body: json.encode(requestBody),
      );

      print("Response Headers: ${response.headers}");
      print("Response Body: ${response.body}");
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        print("Order ${widget.orderId} marked $status successfully");
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

        throw Exception('Failed to update order ${widget.orderId} to $status');
      }
    } catch (e) {
      print('Error updating order ${widget.orderId}: $e');
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading  = true;
    });
    final cameras = await availableCameras();
    _controller = CameraController(cameras[1], ResolutionPreset.medium);
    await _controller.initialize();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isCameraInitialized = true;
    });
  }

  Future<void> _createCall() async {
    setState(() {
      _isLoading = true;
    });
    _controller.dispose();
    try {
      String callId = generateRandomCallId();
      String? url = dotenv.env['URL'];
      String? token = await readValue();
      String? endpoint = "$url/meeting";
      final requestBody = json.encode({
        'celeb_username': widget.celebUsername,
        'fan_username': widget.fanUsername,
        'callid': callId,
        'orderid': widget.orderId,
      });
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http.post(
        Uri.parse(endpoint),
        headers: requestHeaders,
        body: requestBody,
      );

      print('Request Body: $requestBody');
      print('Request Headers: $requestHeaders');
      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Celeb token: ${responseData['meeting']['celeb_token']}');
        StreamVideo.reset();
        client = StreamVideo(
          '4e7xphj2343z',
          user: User.regular(
            userId: responseData['meeting']['celeb_username'],
            role: 'admin',
            name: responseData['meeting']['celeb_username'],
          ),
          userToken: responseData['meeting']['celeb_token'],
        );
        var call = client.makeCall(
          callType: StreamCallType(),
          id: callId,
        );

        await call.getOrCreate();
        _patchStatus('inprogress');
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              call: call,
              celebUsername: widget.celebUsername,
              patchStatus: _patchStatus,
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
                color: Colors.white,
              ),
            ),
          ),
        );
        print('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error joining or creating call: $e');
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  fontSize: 18

              )
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.readexPro(
              textStyle: TextStyle(
                  fontSize: 15

              )
          ),
        ),
        SizedBox(height: 12),
      ],
    );
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
              _buildDetailsBox(),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCall,
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
                    'Create Call',
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
  final String celebUsername;
  final Future<void> Function(String status) patchStatus;

  const CallScreen({
    Key? key,
    required this.call,
    required this.celebUsername,
    required this.patchStatus,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Future<void> _handleLeaveCall() async {
    await widget.patchStatus('completed'); // Update status to "completed"
    await widget.call.leave(); // Leave the call
    Navigator.pop(context);
    // Navigate back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamCallContainer(
        call: widget.call,
        callContentBuilder: (
            BuildContext context,
            Call call,
            CallState callState,
            ) {
          PreferredSizeWidget _buildCallAppBar(BuildContext context, Call call, CallState callState) {
            return AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: Text('Call with ${widget.celebUsername}', style: GoogleFonts.readexPro(
                color: Colors.white
              ),),
              leading: Container(),
              centerTitle: true,
            );
          }
          return StreamCallContent(
            callAppBarBuilder: _buildCallAppBar,
            call: call,
            callState: callState,
            callControlsBuilder: (
                BuildContext context,
                Call call,
                CallState callState,
                ) {
              final localParticipant = callState.localParticipant!;
              return StreamCallControls(
                backgroundColor: Theme.of(context).colorScheme.primary,
                options: [
                  ToggleSpeakerphoneOption(call: call),
                  FlipCameraOption(
                    call: call,
                    localParticipant: localParticipant,
                  ),
                  ToggleMicrophoneOption(
                    call: call,
                    localParticipant: localParticipant,
                  ),
                  ToggleCameraOption(
                    call: call,
                    localParticipant: localParticipant,
                  ),
                  LeaveCallOption(
                    call: call,
                    onLeaveCallTap: _handleLeaveCall,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
