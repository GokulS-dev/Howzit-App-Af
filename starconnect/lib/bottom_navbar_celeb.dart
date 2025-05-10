import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';
import 'order_history_screen_celeb.dart';
import 'create_post.dart';
import 'profile_screen.dart';
import 'settings.dart';
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
String? endpoint = '$apiurl/celeb';

Future<String> fetchProfile(String username) async {
  String? token = await readValue();
  final Uri uri = Uri.parse("$endpoint/$username");
  print('Fetching profile for username: $username');
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
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching profile: $e');
    throw Exception('Error fetching profile: $e');
  }
}

class BottomNavigationBarWidgetCeleb extends StatefulWidget {
  final String username;
  final int userId;
  const BottomNavigationBarWidgetCeleb({Key? key, required this.username, required this.userId})
      : super(key: key);

  @override
  State<BottomNavigationBarWidgetCeleb> createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState
    extends State<BottomNavigationBarWidgetCeleb> {
  late CelebNavigationController controller;
  late Future<String> _profileFuture; // Future to hold profile data

  @override
  void initState() {
    super.initState();
    controller = Get.put(CelebNavigationController());
    _profileFuture = fetchProfile(widget.username); // Initialize profile fetch
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _profileFuture,
      builder: (context, snapshot) {
        List<Widget> screens = [
          HomeScreen(userName: widget.username, userId: widget.userId,),
          OrderHistoryScreenCeleb(username: widget.username,),
          CreatePostScreen(username: widget.username),
          snapshot.connectionState == ConnectionState.done
              ? ProfileScreen(jsonString: snapshot.data!)
              : Center(child: CircularProgressIndicator()),
          const SettingScreen(),
        ];

        return Scaffold(
          bottomNavigationBar: Obx(
            () => NavigationBar(
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              indicatorColor: Theme.of(context).colorScheme.primary,
              height: 60,
              elevation: 0,
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected: (index) {
                controller.selectedIndex.value = index;
              },
              destinations: const [
                NavigationDestination(
                  label: 'Home',
                  icon: Icon(Icons.home_rounded, size: 28),
                  selectedIcon:
                      Icon(Icons.home_rounded, size: 28),
                ),
                NavigationDestination(
                  label: 'Orders',
                  icon: Icon(Icons.shopping_cart_rounded, size: 28),
                  selectedIcon: Icon(Icons.shopping_cart_rounded,
                       size: 28),
                ),
                NavigationDestination(
                  label: 'Create Post',
                  icon: Icon(Icons.add, size: 28),
                  selectedIcon: Icon(Icons.add, size: 28),
                ),
                NavigationDestination(
                  label: 'Profile',
                  icon: Icon(Icons.person, size: 28),
                  selectedIcon:
                      Icon(Icons.person, size: 28),
                ),
                NavigationDestination(
                  label: 'Settings',
                  icon: Icon(Icons.settings, size: 28),
                  selectedIcon:
                      Icon(Icons.settings, size: 28),
                ),
              ],
            ),
          ),
          body: Obx(
            () {
              return IndexedStack(
                index: controller.selectedIndex.value,
                children: screens,
              );
            },
          ),
        );
      },
    );
  }
}

class CelebNavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
}
