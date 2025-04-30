class Order {
  final String occasion;
  final String date;
  final String wishesTo;
  final String details;
  final String celebrityName;

  Order({
    required this.occasion,
    required this.date,
    required this.wishesTo,
    required this.details,
    required this.celebrityName,
  });
}

class OrderData {
  static List<Order> orders = [];

  static void addOrder(Order order) {
    orders.add(order);
  }
}
