import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
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
class FeedPage extends StatefulWidget {
  final String userName;

  const FeedPage({Key? key, required this.userName}) : super(key: key);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<List<Map<String, dynamic>>> feed = [];

  @override
  void initState() {
    super.initState();
    fetchFeed(widget.userName);
  }

  Future<void> feedRefresh() async {
    await fetchFeed(widget.userName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          'Feed refreshed successfully',
          style: GoogleFonts.readexPro(
            color: Colors.white,
          ),
        ),
      ),
    );
  }


  Future<void> fetchFeed(String userName) async {
    String? token = await readValue();
    String? url = dotenv.env['URL'];
    String feedEndpoint = "$url/fan/${widget.userName}/feed";
    print("Feed Endpoint: $feedEndpoint");


    Map<String, dynamic> requestBody = {
      'username': userName,
    };

    Map<String, String> requestHeaders = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
    print("Feed Request Headers: $requestHeaders");

    try {
      final response = await http.get(
        Uri.parse(feedEndpoint),
        headers: requestHeaders,
      );
Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        print('Feed Response Body: ${response.body}');
        setState(() {
          final parsedResponse = json.decode(response.body);
          if (parsedResponse.containsKey('feed')) {
            // Parse the nested list structure correctly
            feed = (parsedResponse['feed'] as List<dynamic>).map((innerList) {
              return (innerList as List<dynamic>).map((post) {
                return post as Map<String, dynamic>;
              }).toList();
            }).toList();
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
            throw Exception('Invalid response format: missing "feed" key');
          }
        });
      } else {
        throw Exception('Failed to get feed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting feed: $e');
    }
  }

  String getProfilePicUrl(String celebname) {
    print("Profile Pic URL: https://starconnectz-store-profilepics.s3.amazonaws.com/${celebname}-profile-pic");
    return 'https://starconnectz-store-profilepics.s3.amazonaws.com/$celebname-profile-pic';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Feed',
          style: GoogleFonts.readexPro(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: feedRefresh,
        child: ListView.builder(
          itemCount: feed.length,
          itemBuilder: (context, index) {
            final posts = feed[index];
            return Column(
              children: posts.map((post) {
                String celebname = post['celeb_username'];
                String profilePicUrl = getProfilePicUrl(celebname);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(profilePicUrl),
                        ),
                        title: Text(
                          celebname,
                          style: GoogleFonts.readexPro(
                        fontSize: 22.0,
                        fontWeight: FontWeight.normal,
                      ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          post['caption'] ?? '',
                          style: GoogleFonts.readexPro(
                        fontSize: 14.0,
                        fontWeight: FontWeight.normal,
                      ),
                        ),
                      ),
                      if (post['imageURL'] != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 3 / 4, // Adjust this ratio as needed
                              child: Image.network(
                                post['imageURL'],
                                fit: BoxFit.cover
                                ,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.thumb_up_alt_outlined),
                              onPressed: () {
                                // Handle like action
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.thumb_down_alt_outlined),
                              onPressed: () {
                                // Handle dislike action
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.comment_outlined),
                              onPressed: () {
                                // Handle comment action
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

