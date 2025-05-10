import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './DataModels/Celebrity.dart';
import 'celebrity_details_screen.dart';
import 'profile_screen.dart';
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

Future<String?> readCountry() async {
  String? country = await _storage.read(key: 'country');
  return country;
}

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
String? apiurl = dotenv.env['API_URL'];

String celebDetailsEndpoint = "$apiurl/celeb/";

class HomeScreen extends StatefulWidget {
  final String userName;
  final int userId;
  const HomeScreen({Key? key, required this.userName, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {

  final TextEditingController _searchController = TextEditingController();
  List<Celebrity> _searchResult = [];
  List<Celebrity> _celebrities = [];
  bool _isLoading = false;
  Future<void> fetchCelebrityDetails(String username) async {
    Map<String, String> reqBody = {"username": username};
    String? token = await readValue();
    try {
      final response = await http.get(
        Uri.parse(celebDetailsEndpoint + username),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      // Print request details
      print('Request URL: ${Uri.parse(celebDetailsEndpoint + username)}');
      print('Request Headers: ${{
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }}');
      print('Request Body: $reqBody');

      if (response.statusCode == 200) {
        // Parse the JSON response
        Map<String, dynamic> data = jsonDecode(response.body);
        print("Response Body : $data");

        // Check if the username matches
        if (username == widget.userName) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                jsonString: response.body,
              ),
            ),
          );
        } else {
          // Navigate to the CelebrityDetailsScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CelebrityDetailsScreen(
                username: widget.userName,
                jsonString: response.body,
                userId: widget.userId,
              ),
            ),
          );
        }

        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
      } else {
        Map<String, dynamic> responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'],
              style: GoogleFonts.readexPro(
              ),
            ),
          ),
        );
        throw Exception(
            'Failed to load celebrity details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load celebrity details: $e');
    }
  }

  Future<void> fetchCelebrities() async {
    String? country = await readCountry();
    String displayAllCelebsEndpoint = "$apiurl/celeb/country/$country";
    setState(() {
      _isLoading = true; // Set loading state to true
    });
    try {
      String? token = await readValue();
      final response = await http.get(Uri.parse(displayAllCelebsEndpoint),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }).timeout(const Duration(seconds: 10));

      print("Response Data Home Screen: ${response.body}");

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> celebJsonList = data["celebs"];
        _celebrities =
            celebJsonList.map((json) => Celebrity.fromJson(json)).toList();
      } else {
        Map<String, dynamic> responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'],
              style: GoogleFonts.readexPro(
              ),
            ),
          ),
        );
      }
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load celebrities: $e',
            style: GoogleFonts.readexPro(
            ),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false
      });
    }
    // DO NOT REMOVE
    // // Simulated list of celebrities for demonstration
    // final List<Celebrity> celebrities = [
    //   Celebrity(name: 'Kavin', profile_pic: 'assets/kavin.jpg'),
    //   Celebrity(name: 'IrfansView', profile_pic: 'assets/irfan.jpg'),
    //   Celebrity(name: 'Aadhi', profile_pic: 'assets/aadhi.jpg'),
    //   Celebrity(name: 'Anirudh', profile_pic: 'assets/anirudh.jpg'),
    //   Celebrity(name: 'Soori', profile_pic: 'assets/soori.jpg'),
    //   Celebrity(name: 'VJ Sidhu', profile_pic: 'assets/vjsidhu.jpg'),
    //   Celebrity(name: 'Natarajan', profile_pic: 'assets/natarajan.jpg'),
    //   Celebrity(name: 'Pugazh', profile_pic: 'assets/pugazh.jpg'),
    // ];

    // }
    // return celebrities;
    // DO NOT REMOVE
  }

  @override
  void initState() {
    super.initState();
    _celebrities = []; // Initialize empty list
    fetchCelebrities(); // Fetch celebrities once when initializing
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        child: Scaffold(
          body: _isLoading? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.secondary,
                ),
              )
          ) : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 10),
                _buildSearchSection(_celebrities),
                const SizedBox(height: 20),
                _buildCelebrityGrid(context, _celebrities),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome, ',
                  style: GoogleFonts.readexPro(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                TextSpan(
                  text: widget.userName.capitalize(),
                  style: GoogleFonts.readexPro(
                    fontSize: 30,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '!',
                  style: GoogleFonts.readexPro(
                    fontSize: 30,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<String?>(
            future: readCountry(), // Fetch the country code
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Show loading indicator
              } else if (snapshot.hasError) {
                return Icon(Icons.error); // Handle error case
              } else if (snapshot.hasData) {
                final country = snapshot.data;
                return Image.network(
                  width: 38, // Adjust size as needed
                  height: 38,
                  'https://flagsapi.com/${country ?? 'US'}/shiny/64.png', // Default to 'US' if country is null
                );
              } else {
                return Icon(Icons.error); // Handle case when no data is available
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(List<Celebrity> celebrities) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 24,
                  ),
                  hintText: 'Search for your favourite celebrities',
                  hintStyle: GoogleFonts.readexPro(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w100,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchResult = celebrities
                        .where((celebrity) => celebrity.name
                            .toLowerCase()
                            .startsWith(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrityGrid(
      BuildContext context, List<Celebrity> celebrities) {
    List<Celebrity> displayCelebrities =
        _searchController.text.isEmpty ? celebrities : _searchResult;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 4,
          mainAxisSpacing: 15, // Space between rows
          crossAxisSpacing: 10, // Space between columns
        ),
        itemCount: displayCelebrities.length,
        itemBuilder: (context, index) {
          Celebrity celebrity = displayCelebrities[index];
          return _buildCelebrityCard(context, celebrity);
        },
      ),
    );
  }

  Widget _buildCelebrityCard(BuildContext context, Celebrity celebrity) {
    return GestureDetector(
      onTap: () async {
        try {
          await fetchCelebrityDetails(celebrity.name);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: Colors.transparent,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 164,
              height: 252,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(

                    width: 160,
                    height: 150,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(celebrity.profile_pic),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          celebrity.name.capitalize(),
                          style: GoogleFonts.readexPro(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import './DataModels/Celebrity.dart';
// import 'celebrity_details_screen.dart';
// import 'profile_screen.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// final FlutterSecureStorage _storage = FlutterSecureStorage();
// Future<String?> readValue() async {
//   String? value = await _storage.read(key: 'token');
//
//
//   if (value != null) {
//     print('Stored value: $value');
//   } else {
//     print('No value found');
//   }
//   return value;
// }
//
// Future<String?> readCountry() async {
//   String? country = await _storage.read(key: 'country');
//   return country;
// }
//
// extension StringExtensions on String {
//   String capitalize() {
//     return "${this[0].toUpperCase()}${this.substring(1)}";
//   }
// }
// String? apiurl = dotenv.env['API_URL'];
//
// String celebDetailsEndpoint = "$apiurl/celeb/";
//
// class HomeScreen extends StatefulWidget {
//   final String userName;
//   final int userId;
//   const HomeScreen({Key? key, required this.userName, required this.userId}) : super(key: key);
//
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
//
// class _HomeScreenState extends State<HomeScreen> {
//
//   final TextEditingController _searchController = TextEditingController();
//   List<Celebrity> _searchResult = [];
//   List<Celebrity> _celebrities = [];
//   bool _isLoading = false;
//   Future<void> fetchCelebrityDetails(String username) async {
//     Map<String, String> reqBody = {"username": username};
//     String? token = await readValue();
//     try {
//       final response = await http.get(
//         Uri.parse(celebDetailsEndpoint + username),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token"
//         },
//       );
//
//       // Print request details
//       print('Request URL: ${Uri.parse(celebDetailsEndpoint + username)}');
//       print('Request Headers: ${{
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token"
//       }}');
//       print('Request Body: $reqBody');
//
//       if (response.statusCode == 200) {
//         // Parse the JSON response
//         Map<String, dynamic> data = jsonDecode(response.body);
//         print("Response Body : $data");
//
//         // Check if the username matches
//         if (username == widget.userName) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ProfileScreen(
//                 jsonString: response.body,
//               ),
//             ),
//           );
//         } else {
//           // Navigate to the CelebrityDetailsScreen
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => CelebrityDetailsScreen(
//                 username: widget.userName,
//                 jsonString: response.body,
//                 userId: widget.userId,
//               ),
//             ),
//           );
//         }
//
//         print('Response Headers: ${response.headers}');
//         print('Response Body: ${response.body}');
//       } else {
//         Map<String, dynamic> responseData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               responseData['message'],
//               style: GoogleFonts.readexPro(
//               ),
//             ),
//           ),
//         );
//         throw Exception(
//             'Failed to load celebrity details: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load celebrity details: $e');
//     }
//   }
//
//   Future<void> fetchCelebrities() async {
//     String? country = await readCountry();
//     String displayAllCelebsEndpoint = "$apiurl/celeb/country/$country";
//     setState(() {
//       _isLoading = true; // Set loading state to true
//     });
//     try {
//       String? token = await readValue();
//       final response = await http.get(Uri.parse(displayAllCelebsEndpoint),
//           headers: {
//             "Content-Type": "application/json",
//             "Authorization": "Bearer $token"
//           }).timeout(const Duration(seconds: 10));
//
//       print("Response Data Home Screen: ${response.body}");
//
//       if (response.statusCode == 200) {
//         Map<String, dynamic> data = json.decode(response.body);
//         List<dynamic> celebJsonList = data["celebs"];
//         _celebrities =
//             celebJsonList.map((json) => Celebrity.fromJson(json)).toList();
//       } else {
//         Map<String, dynamic> responseData = json.decode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               responseData['message'],
//               style: GoogleFonts.readexPro(
//               ),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Failed to load celebrities: $e',
//             style: GoogleFonts.readexPro(
//             ),
//           ),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = true; // Set loading state to false
//       });
//     }
//     // DO NOT REMOVE
//     // // Simulated list of celebrities for demonstration
//     // final List<Celebrity> celebrities = [
//     //   Celebrity(name: 'Kavin', profile_pic: 'assets/kavin.jpg'),
//     //   Celebrity(name: 'IrfansView', profile_pic: 'assets/irfan.jpg'),
//     //   Celebrity(name: 'Aadhi', profile_pic: 'assets/aadhi.jpg'),
//     //   Celebrity(name: 'Anirudh', profile_pic: 'assets/anirudh.jpg'),
//     //   Celebrity(name: 'Soori', profile_pic: 'assets/soori.jpg'),
//     //   Celebrity(name: 'VJ Sidhu', profile_pic: 'assets/vjsidhu.jpg'),
//     //   Celebrity(name: 'Natarajan', profile_pic: 'assets/natarajan.jpg'),
//     //   Celebrity(name: 'Pugazh', profile_pic: 'assets/pugazh.jpg'),
//     // ];
//
//     // }
//     // return celebrities;
//     // DO NOT REMOVE
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _celebrities = []; // Initialize empty list
//     fetchCelebrities(); // Fetch celebrities once when initializing
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: SafeArea(
//         child: Scaffold(
//           body: _isLoading? Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   Theme.of(context).colorScheme.secondary,
//                 ),
//               )
//           ) : SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildWelcomeSection(),
//                 const SizedBox(height: 10),
//                 _buildSearchSection(_celebrities),
//                 const SizedBox(height: 20),
//                 _buildCelebrityGrid(context, _celebrities),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildWelcomeSection() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           RichText(
//             text: TextSpan(
//               children: [
//                 TextSpan(
//                   text: 'Welcome, ',
//                   style: GoogleFonts.readexPro(
//                     fontSize: 30,
//                     fontWeight: FontWeight.bold,
//                     color: Theme.of(context).colorScheme.onPrimary,
//                   ),
//                 ),
//                 TextSpan(
//                   text: widget.userName.capitalize(),
//                   style: GoogleFonts.readexPro(
//                     fontSize: 30,
//                     color: Theme.of(context).colorScheme.primary,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 TextSpan(
//                   text: '!',
//                   style: GoogleFonts.readexPro(
//                     fontSize: 30,
//                     color: Theme.of(context).colorScheme.primary,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           FutureBuilder<String?>(
//             future: readCountry(), // Fetch the country code
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return CircularProgressIndicator(); // Show loading indicator
//               } else if (snapshot.hasError) {
//                 return Icon(Icons.error); // Handle error case
//               } else if (snapshot.hasData) {
//                 final country = snapshot.data;
//                 return Image.network(
//                   width: 38, // Adjust size as needed
//                   height: 38,
//                   'https://flagsapi.com/${country ?? 'US'}/shiny/64.png', // Default to 'US' if country is null
//                 );
//               } else {
//                 return Icon(Icons.error); // Handle case when no data is available
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSearchSection(List<Celebrity> celebrities) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Row(
//           children: [
//             const SizedBox(width: 8),
//             Expanded(
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   prefixIcon: Icon(
//                     Icons.search_rounded,
//                     size: 24,
//                   ),
//                   hintText: 'Search for your favourite celebrities',
//                   hintStyle: GoogleFonts.readexPro(
//                     fontSize: 14.0,
//                     fontWeight: FontWeight.w100,
//                   ),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     _searchResult = celebrities
//                         .where((celebrity) => celebrity.name
//                         .toLowerCase()
//                         .startsWith(value.toLowerCase()))
//                         .toList();
//                   });
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCelebrityGrid(
//       BuildContext context, List<Celebrity> celebrities) {
//     List<Celebrity> displayCelebrities =
//     _searchController.text.isEmpty ? celebrities : _searchResult;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           childAspectRatio: 3 / 4,
//           mainAxisSpacing: 15, // Space between rows
//           crossAxisSpacing: 10, // Space between columns
//         ),
//         itemCount: displayCelebrities.length,
//         itemBuilder: (context, index) {
//           Celebrity celebrity = displayCelebrities[index];
//           return _buildCelebrityCard(context, celebrity);
//         },
//       ),
//     );
//   }
//
//   Widget _buildCelebrityCard(BuildContext context, Celebrity celebrity) {
//     return GestureDetector(
//       onTap: () async {
//         try {
//           await fetchCelebrityDetails(celebrity.name);
//         } catch (e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error: ${e.toString()}')),
//           );
//         }
//       },
//       child: Padding(
//         padding: const EdgeInsets.all(2),
//         child: Material(
//           color: Colors.transparent,
//           elevation: 5,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Container(
//               width: 164,
//               height: 252,
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.surface,
//                 boxShadow: const [
//                   BoxShadow(
//                     blurRadius: 6,
//                     offset: Offset(0, 2),
//                   )
//                 ],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: Colors.transparent,
//                   width: 1,
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.max,
//                 children: [
//                   Container(
//
//                     width: 160,
//                     height: 150,
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         fit: BoxFit.cover,
//                         image: NetworkImage(celebrity.profile_pic),
//                       ),
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(8),
//                         topRight: Radius.circular(8),
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(8),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         Text(
//                           celebrity.name.capitalize(),
//                           style: GoogleFonts.readexPro(
//                             fontSize: 17,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//}