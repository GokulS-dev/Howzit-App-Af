import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:star_connectz/personal_time_fan.dart';
import 'package:star_connectz/reject_reason.dart';
import 'package:url_launcher/url_launcher.dart';

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

class OrderHistoryScreenFan extends StatefulWidget {
  final String username;

  const OrderHistoryScreenFan({Key? key, required this.username})
      : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreenFan> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  String _getButtonText(String serviceDetails) {
    switch (serviceDetails) {
      case 'Video Message':
        return 'Download Video';
      case 'Personal Time':
        return 'Personal Time';
      default:
        return 'Download Audio';
    }
  }

  Future<void> _fetchOrderHistory() async {
    String? token = await readValue();
    String? url = dotenv.env['URL'];
    String orderHistoryEndpoint = "$url/order/fan/${widget.username}";
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
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              responseData['message']!,
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
  Future<void> _deleteOrder(int id) async {
    String? token = await readValue();
    String? url = dotenv.env['URL'];
    String orderEndpoint = "$url/order/$id";
    Map<String, String> reqHeader = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    };

    try {
      final response = await http.delete(
        Uri.parse(orderEndpoint),
        headers: reqHeader,
      );

      print("Order Delete Endpoint : $orderEndpoint");
      print("Order Delete Request Header: $reqHeader");
      print("Order Delete Response Header: ${response.headers}");
      print("Order Delete Response Body: ${response.body}");
      Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        print("Order $id deleted successfully");
        setState(() {
          OrderData.orders.removeWhere((order) => order.id == id);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              responseData['message']!,
              style: GoogleFonts.readexPro(
                color: Colors.white,
              ),
            ),
          ),
        );
        throw Exception('Failed to delete order $id');
      }
      print("Delete Order Response: ${response.body}");
    } catch (e) {
      print('Error deleting order $id: $e');
    }
  }

  Future<void> _confirmDeleteOrder(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(
            "Confirm Delete",
            style: GoogleFonts.readexPro(
              color: Colors.white,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this order?",
            style: GoogleFonts.readexPro(
              color: Colors.white,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Cancel",
                style: GoogleFonts.readexPro(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "Delete",
                style: GoogleFonts.readexPro(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteOrder(id);
              },
            ),
          ],
        );
      },
    );
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
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RefreshIndicator(
                    onRefresh: _refreshOrders,
                    child: ListView.builder(
                      itemCount: OrderData.orders.length,
                      itemBuilder: (context, index) {
                        final order = OrderData.orders[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  order.celeb_username,
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
                                padding: const EdgeInsets.all(6.0),
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
                              if ((order.status == "completed" &&
                                      (order.service_details ==
                                              "Audio Message" ||
                                          order.service_details ==
                                              "Video Message")) ||
                                  (order.status == "inprogress" &&
                                      order.service_details ==
                                          "Personal Time") ||
                                  (order.status == "rejected"))
                                _buildButton(order),
                              if (order.status != "completed" &&
                                  order.status != "inprogress")
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _confirmDeleteOrder(order.id);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildButton(Order order) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
            onPressed: () {
              if (order.status == "rejected") {
                _buildDialogBox(context, order.reject_reason);
                return;
              }
              if (order.service_details == 'Personal Time') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PersonalTimeFanPage(
                            orderId: order.id,
                          )),
                );
              } else {
                _downloadFile(order);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              order.status == "rejected" ? "View Reason" : _getButtonText(order.service_details),
              style: GoogleFonts.readexPro(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF171c2e),
              ),
            )),
      ),
    );
  }

  Future<void> _downloadFile(Order order) async {
    String? token = await readValue();
    String? url = dotenv.env['URL'];
    String fileUrl; // Declare fileUrl here
    String downloadEndpoint = "$url/order/getDetails/${order.id}";

    try {
      final response = await http.get(
        Uri.parse(downloadEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(
            "Response Data Downloading Files: ${responseData['order']['videoURL']}");
        if (order.service_details == "Video Message") {
          fileUrl = responseData['order']['videoURL'];
        } else {
          fileUrl = responseData['order']['audioURL'];
        }
        // Launch the URL to download the file
        await launchUrl(Uri.parse(fileUrl));
      } else {
        Map<String, dynamic> responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              responseData['message']!,
              style: GoogleFonts.readexPro(
                color: Colors.white,
              ),
            ),
          ),
        );

        throw Exception('Failed to fetch download URL');
      }
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file. Please try again later.'),
        ),
      );
    }
  }

  Future<void> _refreshOrders() async {
    await _fetchOrderHistory();

    if (OrderData.orders.isEmpty) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              'No order history as of now',
              style: GoogleFonts.readexPro(color: Colors.white),
            ),
          ),
        );
      });
    }
  }
}

void _buildDialogBox(BuildContext context, String reject_reason) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          "Rejection Reason",
          style: GoogleFonts.readexPro(
            color: Colors.white,
          ),
        ),
        content: Text(
          reject_reason,
          style: GoogleFonts.readexPro(
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              "OK",
              style: GoogleFonts.readexPro(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


class OrderData {
  static List<Order> orders = [];
}

class Order {
  final String celeb_username;
  final String service_details;
  final String created_at;
  final int price;
  final String status;
  final String reject_reason;
  final int id;

  Order({
    required this.celeb_username,
    required this.service_details,
    required this.created_at,
    required this.reject_reason,
    required this.price,
    required this.status,
    required this.id,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      celeb_username: json['celeb_username'],
      service_details: json['service_details'],
      created_at: json['created_at'],
      reject_reason: json['reject_reason'],
      price: json['price'],
      status: json['status'],
      id: json['id'],
    );
  }
}
