import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:star_connectz/create_post.dart';
import 'home_screen.dart';
import 'settings.dart';
import 'order_history_screen_fan.dart';
import 'profile_screen.dart';
import 'feed.dart';

class BottomNavigationBarWidgetFan extends StatefulWidget {
  final String username;
  final int userid;

  const BottomNavigationBarWidgetFan({Key? key, required this.username, required this.userid})
      : super(key: key);

  @override
  State<BottomNavigationBarWidgetFan> createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState
    extends State<BottomNavigationBarWidgetFan> {
  late FanNavigationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FanNavigationController());
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      HomeScreen(userName: widget.username, userId: widget.userid,),
      FeedPage(userName: widget.username),
      OrderHistoryScreenFan(username: widget.username,),
      // ProfileScreen(
      //   jsonString:
      //       '{"user": {"id": 1, "username": "Rishi", "email": "rishi@gmail.com", "socials": "insta", "password": "password", "verified": false, "createdAt": "2024-06-12T19:52:37.670Z", "bio": "get biod", "profile_pic": "https://starconnectz-store-profilepics.s3.amazonaws.com/Rishi-profile-pic", "followers": [{"id": 1, "username": "Surya", "email": "surya@gmail.com", "phone": "12345678", "password": "password", "verified": false, "createdAt": "2024-06-12T20:00:36.734Z"}], "services": [{"id": 1, "amount": 400, "details": "Birthday Wish", "status": "active", "celebid": 1, "timeNeeded": 3}, {"id": 2, "amount": 600, "details": "Personal message", "status": "active", "celebid": 1, "timeNeeded": 5}, {"id": 3, "amount": 400, "details": "Birthday Wish", "status": "active", "celebid": 1, "timeNeeded": 3}, {"id": 4, "amount": 600, "details": "Personal message", "status": "active", "celebid": 1, "timeNeeded": 5}, {"id": 5, "amount": 400, "details": "Birthday Wish", "status": "active", "celebid": 1, "timeNeeded": 3}, {"id": 6, "amount": 600, "details": "Personal message", "status": "active", "celebid": 1, "timeNeeded": 5}], "posts": [{"id": 4, "caption": "Hello there", "imageName": "imageName", "celebname": "Rishi", "celebid": 1, "createdAt": "2024-06-12T20:16:18.358Z", "imageURL": "https://starconnectz-store-posts.s3.ap-south-1.amazonaws.com/imageURL"}, {"id": 3, "caption": "secondoneagain", "imageName": "imageName", "celebname": "Rishi", "celebid": 1, "createdAt": "2024-06-12T19:58:37.272Z", "imageURL": "https://starconnectz-store-posts.s3.ap-south-1.amazonaws.com/imageURL"}, {"id": 2, "caption": "secondone", "imageName": "imageName", "celebname": "Rishi", "celebid": 1, "createdAt": "2024-06-12T19:56:52.278Z", "imageURL": "https://starconnectz-store-posts.s3.ap-south-1.amazonaws.com/imageURL"}]}}',
      // ),
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
              Icon(Icons.home_rounded,  size: 28),
            ),
            NavigationDestination(
              label: 'Feed',
              icon: Icon(Icons.feed, size: 28),
              selectedIcon:
                  Icon(Icons.feed,  size: 28),
            ),

            NavigationDestination(
              label: 'Orders',
              icon: Icon(Icons.shopping_cart_rounded, size: 28),
              selectedIcon: Icon(Icons.shopping_cart_rounded,
                   size: 28),
            ),

            // NavigationDestination(
            //   label: 'Profile',
            //   icon: Icon(Icons.person, size: 28),
            //   selectedIcon:
            //       Icon(Icons.person, color: Color(0xFF8EBBFF), size: 28),
            // ),
            NavigationDestination(
              label: 'Settings',
              icon: Icon(Icons.settings, size: 28),
              selectedIcon:
                  Icon(Icons.settings,  size: 28),
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
  }
}

class FanNavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
}
