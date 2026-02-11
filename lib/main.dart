import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Purchase Log',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PurchaseLogPage(),
    );
  }
}

class Purchase {
  final String itemName;
  final String date;
  final String timeLogged;
  final String purchaserName;
  final String vendor;
  final double price;
  final String details;
  final List<String> uploadedFiles;

  Purchase({
    required this.itemName,
    required this.date,
    required this.timeLogged,
    required this.purchaserName,
    required this.vendor,
    required this.price,
    required this.details,
    required this.uploadedFiles,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      itemName: json['itemName'],
      date: json['date'],
      timeLogged: json['timeLogged'],
      purchaserName: json['purchaserName'],
      vendor: json['vendor'],
      price: (json['price'] as num).toDouble(),
      details: json['details'],
      uploadedFiles: List<String>.from(json['uploadedFiles'] ?? []),
    );
  }
}

class PurchaseLogPage extends StatefulWidget {
  const PurchaseLogPage({super.key});

  @override
  State<PurchaseLogPage> createState() => _PurchaseLogPageState();
}

class _PurchaseLogPageState extends State<PurchaseLogPage> {
  final TextEditingController searchController = TextEditingController();
  List<Purchase> allPurchases = [];
  List<Purchase> filteredPurchases = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    try {
      print('Attempting to load JSON file...');
      
      // Load the JSON file from assets using rootBundle
      final String jsonString = await rootBundle.loadString('assets/json/fake_purchase_log.json');
      print('JSON loaded successfully: ${jsonString.length} characters');
      
      final List<dynamic> data = json.decode(jsonString);
      print('JSON parsed successfully: ${data.length} items');
      
      setState(() {
        allPurchases = data.map((json) => Purchase.fromJson(json)).toList();
        filteredPurchases = allPurchases;
        loading = false;
        errorMessage = null;
      });
      
      print('Purchases loaded: ${allPurchases.length} items');
    } catch (e) {
      print('ERROR loading purchases: $e');
      setState(() {
        loading = false;
        errorMessage = 'Error loading data: $e';
      });
    }
  }

  void filterSearch(String query) {
    setState(() {
      filteredPurchases = allPurchases
          .where((p) =>
              p.itemName.toLowerCase().contains(query.toLowerCase()) ||
              p.purchaserName.toLowerCase().contains(query.toLowerCase()) ||
              p.date.contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Log"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              loading = true;
                              errorMessage = null;
                            });
                            loadPurchases();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        onChanged: filterSearch,
                        decoration: InputDecoration(
                          hintText: "Search by item, purchaser, or date...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: filteredPurchases.isEmpty
                            ? const Center(
                                child: Text(
                                  'No purchases found',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text("Item Name")),
                                    DataColumn(label: Text("Date")),
                                    DataColumn(label: Text("Purchaser Name")),
                                  ],
                                  rows: filteredPurchases
                                      .map(
                                        (purchase) => DataRow(
                                          cells: [
                                            DataCell(
                                              Text(purchase.itemName),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PurchaseDetailPage(
                                                            purchase: purchase),
                                                  ),
                                                );
                                              },
                                            ),
                                            DataCell(
                                              Text(purchase.date),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PurchaseDetailPage(
                                                            purchase: purchase),
                                                  ),
                                                );
                                              },
                                            ),
                                            DataCell(
                                              Text(purchase.purchaserName),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PurchaseDetailPage(
                                                            purchase: purchase),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class PurchaseDetailPage extends StatelessWidget {
  final Purchase purchase;

  const PurchaseDetailPage({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(purchase.itemName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Item: ${purchase.itemName}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Date: ${purchase.date}", style: const TextStyle(fontSize: 16)),
            Text("Time Logged: ${purchase.timeLogged}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("Purchaser: ${purchase.purchaserName}",
                style: const TextStyle(fontSize: 16)),
            Text("Vendor: ${purchase.vendor}", style: const TextStyle(fontSize: 16)),
            Text("Price: \$${purchase.price.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text("Details:", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(purchase.details, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text("Uploaded Files:",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            if (purchase.uploadedFiles.isEmpty)
              const Text("No files uploaded")
            else
              ...purchase.uploadedFiles.map(
                (file) => ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(file),
                  onTap: () {
                    // TODO: Open PDF file
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}