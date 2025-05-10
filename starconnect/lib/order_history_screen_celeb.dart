import 'package:flutter/material.dart';
import 'package:get/get_common/get_reset.dart';
import 'package:star_connectz/personal_time_celeb.dart';
import 'package:star_connectz/record_audio.dart';
import 'package:star_connectz/record_video.dart';
import 'package:star_connectz/reject_reason.dart';
import 'order_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

class OrderHistoryScreenCeleb extends StatefulWidget {
  final String username;

  const OrderHistoryScreenCeleb({Key? key, required this.username}) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreenCeleb> {
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedFilter = 'All';

  List<Order> _filteredOrders = [];
  Future<void> _acceptOrder(int id) async {
    String? token = await readValue();
    String? url = dotenv.env['URL'];
    String orderEndpoint = "$url/order/$id";
    Map<String, String> reqHeader = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };
    Map<String, String> requestBody = {
      "status": "accepted" // Update status to "accepted"
    };

    try {
      // Print request headers and body
      print("Request Headers: $reqHeader");
      print("Request Body: ${json.encode(requestBody)}");

      final response = await http.patch(
        Uri.parse(orderEndpoint),
        headers: reqHeader,
        body: json.encode(requestBody),
      );

      // Print response headers and body
      print("Response Headers: ${response.headers}");
      print("Response Body: ${response.body}");
     
      if (response.statusCode == 200) {
        // Update local state or handle success as needed
        print("Order $id accepted successfully");
        setState(() {
          OrderData.orders.firstWhere((order) => order.id == id).status = "accepted";
          _applyFilter();
        });

      } else { Map<String, dynamic> responseData = json.decode(response.body);
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
        throw Exception('Failed to accept order $id');
      }
    } catch (e) {
      print('Error accepting order $id: $e');
    }
  }
  String getServiceActionText(String serviceDetails) {
    if (serviceDetails.contains('Personal')) {
      return 'Personal Time';
    } else if (serviceDetails.contains('Audio')) {
      return 'Record Audio';
    } else if (serviceDetails.contains('Video')) {
      return 'Record Video';
    } else {
      return ''; // Or handle appropriately if you want to show nothing
    }
  }



  // Future<void> _confirmDeleteOrder(int id) async {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Theme.of(context).colorScheme.primary,
  //         title: Text(
  //           "Confirm Delete",
  //           style: GoogleFonts.readexPro(
  //               color: Colors.white
  //           ),
  //         ),
  //         content: Text(
  //           "Are you sure you want to reject this order?",
  //           style: GoogleFonts.readexPro(
  //               color: Colors.white
  //
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text("Cancel",
  //               style: GoogleFonts.readexPro(
  //                   color: Colors.white
  //
  //               ),),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text("Delete",
  //               style: GoogleFonts.readexPro(
  //                   color: Colors.white
  //
  //               ),),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               _rejectOrder(id);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    String? token = await readValue();
    String? url = dotenv.env['URL'];
    String orderHistoryEndpoint = "$url/order/celeb/${widget.username}";
    Map<String, String> reqHeader = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };
    print("Order History Request Headers: $reqHeader");
    try {
      final response = await http.get(
        Uri.parse(orderHistoryEndpoint),
        headers: reqHeader,
      );

Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          OrderData.orders = (data['orders'] as List)
              .map((order) => Order.fromJson(order))
              .toList();
          _isLoading = false;
          _applyFilter();

        });

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
        throw Exception('Failed to load order history');
      }
      print("Order History URL: $orderHistoryEndpoint");
      print("Order History Response: ${response.body}");
    } catch (e) {
      print('Error fetching order history: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Color(0xfff7a102);
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'inprogress':
        return Color(0xfff7a102);
      case 'accepted':
        return Colors.green;
      default:
        return Colors.black; // Default color for unknown statuses
    }
  }
  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredOrders = OrderData.orders;
      } else {
        _filteredOrders = OrderData.orders
            .where((order) => order.status == _selectedFilter.toLowerCase())
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order History',
          style: GoogleFonts.readexPro(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (String result) {
              setState(() {
                _selectedFilter = result;
                _applyFilter();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
               PopupMenuItem<String>(
                value: 'All',
                child: Text('All', style: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.onPrimary)),
              ),
               PopupMenuItem<String>(
                value: 'Pending',
                child: Text('Pending', style: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.onPrimary)),
              ),
               PopupMenuItem<String>(
                value: 'Accepted',
                child: Text('Accepted', style: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.onPrimary)),
              ),
               PopupMenuItem<String>(
                value: 'Completed',
                child: Text('Completed', style: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.onPrimary)),
              ),
               PopupMenuItem<String>(
                value: 'Rejected',
                child: Text('Rejected', style: GoogleFonts.readexPro(color: Theme.of(context).colorScheme.onPrimary)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
        child: Text(
          'Error loading order history',
          style: GoogleFonts.readexPro(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white54,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView.builder(
          itemCount: _filteredOrders.length,
          itemBuilder: (context, index) {
            final order = _filteredOrders[index];
            return Card(
              shadowColor: Colors.black,
              elevation: 10,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      order.fan_username,
                      style: GoogleFonts.readexPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      order.service_details,
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order.created_at.split('T')[0],
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          '₹${order.price}',
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Status: ',
                            style: GoogleFonts.readexPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: Colors.black, // Make sure to set the color
                            ),
                          ),
                          TextSpan(
                            text: order.status.toUpperCase(),
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: getStatusColor(order.status), // Get the color based on status
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (order.status == "pending")
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.green),
                            onPressed: () => _acceptOrder(order.id),
                          ),
                          SizedBox(width: 16),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RejectReason(orderid: order.id,),
                                ),
                              );
                            }


                            // _confirmDeleteOrder(order.id),

                          ),
                        ],
                      ),
                    )
                  else if (order.status =="accepted" ||( order.service_details.contains('Personal') && order.status == "inprogress"))
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle record audio or video
                          if (order.service_details.contains('Audio')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecordAudio(
                                  celebName: widget.username,
                                  fanName: order.fan_username,
                                  orderId: order.id,
                                  wishesTo: order.wishes_to,
                                  occasion: order.occasion,
                                  additionalInfo: order.additional_info,
                                ),
                              ),
                            );
                          } else if (order.service_details.contains('Video')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecordVideo(
                                  celebName: widget.username,
                                  fanName: order.fan_username,
                                  orderId: order.id,
                                  wishesTo: order.wishes_to,
                                  occasion: order.occasion,
                                  additionalInfo: order.additional_info,
                                ),
                              ),
                            );
                          } else if (order.service_details.contains('Personal') && (order.status == "inprogress" || order.status == "accepted")) {
                            // Handle other cases or show a message
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PersonalTimeCelebPage(celebUsername: order.celeb_username, celebId: order.celebid, fanUsername: order.fan_username, fanId: order.fanid, orderId: order.id, wishesTo: order.wishes_to,
                                    occasion: order.occasion,
                                    additionalInfo: order.additional_info,


                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                        ),
                        child: Text(
                          getServiceActionText(order.service_details),
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  Future<void> _refreshOrders() async {
    await _fetchOrderHistory();

    if (OrderData.orders.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text('No order history as of now', style: GoogleFonts.readexPro(
              color: Colors.white
            ),),
          ),
        );
      });
    }
  }
}

class OrderData {
  static List<Order> orders = [];
}

class Order {
  final String wishes_to;
  final String additional_info;
  final String occasion;
  final String celeb_username;
  final String fan_username;
  final String service_details;
  final String created_at;
  final int price;
  final int id;
  final int fanid;
  final int celebid;
  String status;

  Order({
    required this.id,
    required this.fanid,
    required this.celebid,
    required this.wishes_to,
    required this.occasion,
    required this.additional_info,
    required this.celeb_username,
    required this.fan_username,
    required this.service_details,
    required this.created_at,
    required this.price,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      fanid: json['fanid'],
      celebid: json['celebid'],
      wishes_to: json['wishes_to'],
      occasion: json['occassion'],
      additional_info: json['additional_info'],
      celeb_username: json['celeb_username'],
      fan_username: json['fan_username'],
      service_details: json['service_details'],
      created_at: json['created_at'],
      price: json['price'],
      status: json['status'],
    );
  }
}
