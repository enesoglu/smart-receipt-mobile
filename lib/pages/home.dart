import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Receipt>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _refreshReceipts();
  }

  void _refreshReceipts() {
    setState(() {
      _receiptsFuture = _apiService.getReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Receipts"),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: FutureBuilder<List<Receipt>>(
        future: _receiptsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Connection error!"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No receipts found."));
          }

          final receipts = snapshot.data!;

          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final r = receipts[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.receipt, color: Colors.blueAccent),
                  ),
                  title: Text(r.storeName, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(r.date.toString().split(' ')[0]),
                  trailing: Text("${r.totalAmount}₺",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add),
        onPressed: () async {
          var newReceipt = Receipt(
              id: 0,
              storeName: "Apple Store",
              date: DateTime.now(),
              totalAmount: 999.0,
              imagePath: "demo.jpg"
          );

          bool success = await _apiService.addReceipt(newReceipt);
          if (success) {
            _refreshReceipts();
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Receipt added successfully!"))
            );
          }
        },
      ),
    );
  }
}