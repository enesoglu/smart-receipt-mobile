class Receipt {
  final int id;
  final String storeName;
  final DateTime date;
  final double totalAmount;
  final String? imagePath;
  final String? tags;
  final List<ReceiptItem> items;

  Receipt({
    required this.id,
    required this.storeName,
    required this.date,
    required this.totalAmount,
    this.imagePath,
    this.tags,
    this.items = const [],
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] ?? 0,
      storeName: json['storeName'] ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      imagePath: json['imagePath'],
      tags: json['tags'],
      items: json['items'] != null
          ? (json['items'] as List).map((e) => ReceiptItem.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeName': storeName,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'imagePath': imagePath,
      'tags': tags,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String get formattedAmount {
    return '${totalAmount.toStringAsFixed(2)} ₺';
  }

  List<String> get tagsList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((e) => e.trim()).toList();
  }
}

class ReceiptItem {
  final int id;
  final String productName;
  final double price;

  ReceiptItem({
    required this.id,
    required this.productName,
    required this.price,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] ?? 0,
      productName: json['productName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'price': price,
    };
  }
}

class CreateReceiptRequest {
  final String storeName;
  final DateTime date;
  final double totalAmount;
  final String? imagePath;
  final String? tags;
  final List<ReceiptItem> items;

  CreateReceiptRequest({
    required this.storeName,
    required this.date,
    required this.totalAmount,
    this.imagePath,
    this.tags,
    this.items = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'imagePath': imagePath,
      'tags': tags,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}