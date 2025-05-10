
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../DataModels/UserProfile.dart';
import 'booking_screen.dart';

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
String ordersEndpoint = "$apiurl/order";

UserProfile parseUserProfile(String jsonString) {
  final jsonResponse = json.decode(jsonString);
  return UserProfile.fromJson(jsonResponse);
}

bool isFollowing(List<dynamic> followers, String userId) {
  try {bool found = followers.any((follower) => follower['id'] == int.parse(userId));
    return found;
  } catch (e) {
    print('Error parsing JSON or checking userId in followers: $e');
    return false; // Return false in case of any error
  }
}

Future<void> _confirmBookService(BuildContext context, int serviceId, int userId, int celebId, UserProfile userProfile) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Book Service',
          style: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.primary),
        ),
        content: Text(
          'Are you sure you want to book this service?',
          style: GoogleFonts.readexPro(),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: <Widget>[
          TextButton(
            child: Text(
              'Cancel',
              style: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.primary),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(
              'Book',
              style: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.primary),
            ),
            onPressed: () async {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookWishScreen(celebrityName: userProfile.username, celebid: celebId, serviceId: serviceId, userId: userId,),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
Future<int> fetchuserId() async {
  String? userIdStr = await _storage.read(key: 'userId');
  if (userIdStr != null) {
    return int.parse(userIdStr);
  } else {
    throw Exception('userId not found in secure storage');
  }
}



class CelebrityDetailsScreen extends StatefulWidget {
  final String jsonString;
  final String username;
  final int userId;
  const CelebrityDetailsScreen({super.key, required this.jsonString, required this.username, required this.userId});

  @override
  State<CelebrityDetailsScreen> createState() => _CelebrityDetailsScreenState();
}

class _CelebrityDetailsScreenState extends State<CelebrityDetailsScreen> {
  Future<void> _refreshDetails() async {
    String celebDetailsEndpoint = "$apiurl/celeb/";
    Map<String, String> reqBody = {"username": userProfile.username};
    String? token = await readValue();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Text(
            'Authentication token not found',
            style: GoogleFonts.readexPro(
              color: Colors.white,
            ),
          ),
        ),
      );
      return;
    }

    print('Request URL: ${Uri.parse(celebDetailsEndpoint + userProfile.username)}');
    print('Request Headers: ${{
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }}');
    print('Request Body: $reqBody');

    try {
      final response = await http.get(
        Uri.parse(celebDetailsEndpoint + userProfile.username),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      // Print request details
      print('Request URL: ${Uri.parse(celebDetailsEndpoint + userProfile.username)}');
      print('Request Headers: ${{
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }}');
      print('Request Body: $reqBody');

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          userProfile = UserProfile.fromJson(json.decode(response.body));
          following = checkFollowStatus(); // Update following status after refresh
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     backgroundColor: Theme.of(context).colorScheme.primary,
        //     content: Text(
        //       'Celebrity Profile Refreshed',
        //       style: GoogleFonts.readexPro(
        //         color: Colors.white,
        //       ),
        //     ),
        //   ),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              data['message'],
              style: GoogleFonts.readexPro(
                color: Colors.white,
              ),
            ),
          ),
        );
        throw Exception('Failed to load celebrity details: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            'Failed to load celebrity details: $e',
            style: GoogleFonts.readexPro(
              color: Colors.white,
            ),
          ),
        ),
      );
      throw Exception('Failed to load celebrity details: $e');
    }
  }

  Future<void> sendFollowRequest(String userName, String celebName) async {
    try {
      String? token = await readValue();
      String followEndpoint = "$apiurl/fan/follow";

      Map<String, dynamic> requestBody = {
        'fan_username': widget.username,
        'celeb_username': celebName,
      };
      Map<String, String> requestHeaders = {"Content-Type": "application/json", "Authorization": "Bearer $token"};

      print("Follow Request Request Body: $requestBody");
      print("Follow Request Request Headers: $requestHeaders");
      print('Follow Endpoint: $followEndpoint');
      final response = await http.post(
        Uri.parse(followEndpoint),
        headers: requestHeaders,
        body: json.encode(requestBody),
      );
      Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200||response.statusCode == 201) {
        print('Follow request sent successfully!');
        _refreshDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              responseData['message'],
              style: GoogleFonts.readexPro(
                color: Colors.white,
              ),
            ),
          ),
        );
        throw Exception('Failed to send follow request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending follow request: $e');
    }
  }


  Future<void> unsendFollowRequest(String userName, String celebName) async {
    try {
      String? token = await readValue();
      String followEndpoint = "$apiurl/fan/unfollow";

      Map<String, dynamic> requestBody = {
        'fan_username': widget.username,
        'celeb_username': celebName,
      };
      Map<String, String> requestHeaders = {"Content-Type": "application/json", "Authorization": "Bearer $token"};

      print("Follow Request Request Body: $requestBody");
      print("Follow Request Request Headers: $requestHeaders");
      print('Follow Endpoint: $followEndpoint');
      final response = await http.post(
        Uri.parse(followEndpoint),
        headers: requestHeaders,
        body: json.encode(requestBody),
      );
      Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200||response.statusCode == 201) {
        print('Follow request unsent successfully!');
        _refreshDetails();
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
        throw Exception('Failed to unsend follow request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unsending follow request: $e');
    }
  }
  late bool following;
  late UserProfile userProfile;
  @override
  void initState() {
    super.initState();
    userProfile = parseUserProfile(widget.jsonString);
    following = checkFollowStatus();
  }

  bool checkFollowStatus()  {
    String? userIdStr = widget.userId.toString();
    return isFollowing(userProfile.followers, userIdStr);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.readexPro(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(userProfile.profilePicUrl),
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
                              '${userProfile.followersCount}',
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
                              '${userProfile.followingCount}',
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () async {
                          following = await checkFollowStatus() ;

                          if (following) {
                            await unsendFollowRequest(widget.username, userProfile.username);
                          } else {
                            await sendFollowRequest(widget.username, userProfile.username);
                          }

                        },
                      child:
                             Text(
                              following ? 'Following' : 'Follow',
                              style: GoogleFonts.readexPro(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )



                    ),
                  ],
                ),
              ),
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
                      onRefresh: _refreshDetails,
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
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _refreshDetails,
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
                              title: Text(
                                service.description,
                                style: GoogleFonts.readexPro(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Amount: \$${service.price}',
                                style: GoogleFonts.readexPro(
                                  fontSize: 16,
                                ),
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  int userId = await fetchuserId();
                                  await _confirmBookService(context, service.id, userId, service.celebid, userProfile);
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary, // Change the button color if needed
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Book',
                                  style: GoogleFonts.readexPro(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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






}
// Data Models
class Service {
  final int id;
  final int price;
  final String description;
  final int celebid;
  final int time_needed;

  Service({
    required this.id,
    required this.price,
    required this.description,
    required this.celebid,
    required this.time_needed,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      price: json['price'],
      description: json['description'],
      celebid: json['celebid'],
      time_needed: json['time_needed'],
    );
  }
}

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String socials;
  final String profilePicUrl;
  final List<Service> services;
  final List<Post> posts;
  final List<dynamic> followers;
  final int followersCount;
  final int followingCount;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.socials,
    required this.profilePicUrl,
    required this.services,
    required this.posts,
    required this.followers,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var servicesFromJson = json['celeb']['services'] as List;
    List<Service> servicesList =
        servicesFromJson.map((i) => Service.fromJson(i)).toList();

    var postsFromJson = json['celeb']['posts'] as List;
    List<Post> postsList = postsFromJson.map((i) => Post.fromJson(i)).toList();

    return UserProfile(
      id: json['celeb']['id'],
      username: json['celeb']['username'],
      email: json['celeb']['email'],
      socials: json['celeb']['socials'],
      profilePicUrl: json['celeb']['profile_pic'],
      services: servicesList,
      posts: postsList,
      followers: json['celeb']['followers'],
      followersCount: (json['celeb']['followers'] != null) ? json['celeb']['followers'].length : 0,
      followingCount: (json['celeb']['following'] != null) ? json['celeb']['following'].length : 0,
    );
  }
}

class Post {
  final int id;
  final String caption;
  final String imagename;
  final String celeb_username;
  final int celebid;
  final String created_at;
  final String imageURL;

  Post({
    required this.id,
    required this.caption,
    required this.imagename,
    required this.celeb_username,
    required this.celebid,
    required this.created_at,
    required this.imageURL,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      caption: json['caption'],
      imagename: json['imagename'],
      celeb_username: json['celeb_username'],
      celebid: json['celebid'],
      created_at: json['created_at'],
      imageURL: json['imageURL'],
    );
  }
}
