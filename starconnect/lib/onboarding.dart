import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'celeb_onboarding_details.dart';
class OnboardingScreen extends StatefulWidget {
  final String username;
  const OnboardingScreen({Key? key, required this.username}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  final List<Widget> _pages = [
     OnboardingPage(imagePath: 'assets/onboarding/1.jpg',),
     OnboardingPage(imagePath: 'assets/onboarding/2.jpg'),
     OnboardingPage(imagePath: 'assets/onboarding/3.jpg'),
     OnboardingPage(imagePath: 'assets/onboarding/4.jpg'),
  ];

  void _nextPage() {
    setState(() {
      if (_currentPage < _pages.length - 1) {
        _currentPage++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  CelebrityProfileScreen(username: widget.username,),
          ),
        );
        }
    });
  }

  void _skip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>  CelebrityProfileScreen(username: widget.username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _pages[index];
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _skip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Theme.of(context).colorScheme.secondary,
                    foregroundColor: const Color(0xFF171c2e),
                    padding: const EdgeInsets.all(
                        8
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.readexPro(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.surface

                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    _pages.length,
                        (index) => buildDot(index, context),
                  ),
                ),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.all(
                      8
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.readexPro(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.surface
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.black : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  final String imagePath;
  const OnboardingPage({super.key, required this.imagePath});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.pink[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}