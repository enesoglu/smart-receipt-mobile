class Receipt {
  final int id;
  final String storeName;
  final DateTime date;
  final double totalAmount;
  final String? imagePath;

  Receipt({
    required this.id,
    required this.storeName,
    required this.date,
    required this.totalAmount,
    this.imagePath,
  });

  // JSON to Dart object
  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] ?? 0,
      storeName: json['storeName'] ?? '',
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      imagePath: json['imagePath'],
    );
  }

  // Dart object to JSON
  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'imagePath': imagePath,
      'userId': 1, // TODO: demo user
    };
  }
}