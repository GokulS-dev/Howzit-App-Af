import 'dart:convert';
import 'dart:io';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

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

class RecordAudio extends StatefulWidget {
  final String fanName;
  final String celebName;
  final String wishesTo;
  final String occasion;
  final String additionalInfo;
  final int orderId;

  const RecordAudio({
    Key? key,
    required this.fanName,
    required this.celebName,
    required this.wishesTo,
    required this.occasion,
    required this.additionalInfo,
    required this.orderId,
  }) : super(key: key);

  @override
  State<RecordAudio> createState() => _RecordAudioState();
}

class _RecordAudioState extends State<RecordAudio> {
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isRecording = false;
  String? recordingPath;
  TextEditingController descriptionController = TextEditingController();
  bool showDetails = false;
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Audio'),
      ),
      floatingActionButton: _recordingButton(),
      body: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(8),child: _buildUI())),
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
    TextField(
    controller: descriptionController,
    style: GoogleFonts.readexPro(
    ),
    decoration: InputDecoration(
    labelText: 'Description',

    ).applyDefaults(Theme.of(context).inputDecorationTheme),
    ),

        if (recordingPath != null) ...[

          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _playRecording(recordingPath!);
              },
              child: Text(
                'Play Recording',
                style: GoogleFonts.readexPro(),
              ),
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
          SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child:  ElevatedButton(
                onPressed: _isLoading ? null : _uploadAudio,
                child:  _isLoading
                    ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.secondary,
                  ),
                )
                    : Text('Upload', style: GoogleFonts.readexPro(color: Colors.black),),
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
],

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


  void _playRecording(String path) async {
    if (audioPlayer.playing) {
      audioPlayer.stop();
      setState(() {
        isPlaying = false;
      });
    } else {
      print("Playing from: $path");
      await audioPlayer.setFilePath(path);
      audioPlayer.play();
      setState(() {
        isPlaying = true;
      });
    }
  }

  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: () async {
        if (isRecording) {
          String? defaultPath = await audioRecorder.stop();
          setState(() {
            isRecording = false;
            recordingPath = defaultPath;
          });
        } else {
          if (await audioRecorder.hasPermission()) {
            final Directory? appDocumentsDir =
            await getExternalStorageDirectory();
            if (appDocumentsDir != null) {
              final String defaultPath =
              p.join(appDocumentsDir.path, "recording.mp3");
              try {
                await audioRecorder.start(const RecordConfig(),
                    path: defaultPath);
                setState(() {
                  isRecording = true;
                  recordingPath = null;
                });
              } catch (e) {
                print('Error starting recording: $e');
                // Handle error, show message to user, etc.
              }
            } else {
              // Handle case where documents directory is null
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  content: Text('Failed to access documents directory!', style: GoogleFonts.readexPro(
                      color: Colors.white
                  ),),
                ),
              );
            }
          } else {
            // Handle case where permissions are not granted
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                content: Text('Permission not granted to record audio.', style: GoogleFonts.readexPro(
                    color: Colors.white
                ),),
              ),
            );
          }
        }
      },
      child: Icon(isRecording ? Icons.stop : Icons.mic),
    );
  }

  Future<void> _uploadAudio() async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });
    String? token = await readValue();
    String? baseurl = dotenv.env['URL'];

    if (recordingPath == null) {
      return; // No recording to upload
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
      final url = Uri.parse('$baseurl/audios');
      final request = http.MultipartRequest('POST', url);

      // Attach the audio file
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        recordingPath!,
        contentType: MediaType('audio', 'mpeg'),
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
            content: Text('Audio uploaded successfully!', style: GoogleFonts.readexPro(
              color: Colors.white
            ),),
          ),
        );
      } else {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text('Failed to upload audio. Please try again later.', style: GoogleFonts.readexPro(
                color: Colors.white
            ),),
          ),
        );
      }
    } catch (e) {
      print('Error uploading audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Error uplaoding audio. Please try again later.', style: GoogleFonts.readexPro(
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
    audioPlayer.dispose();
    super.dispose();
  }
}
