import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:css/css.dart';

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
      theme: CSS.changeTheme(LsiThemes.light),
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

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'date': date,
      'timeLogged': timeLogged,
      'purchaserName': purchaserName,
      'vendor': vendor,
      'price': price,
      'details': details,
      'uploadedFiles': uploadedFiles,
    };
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

  int? _sortColumnIndex;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/json/fake_purchase_log.json');
      final List<dynamic> data = json.decode(jsonString);

      setState(() {
        allPurchases = data.map((json) => Purchase.fromJson(json)).toList();
        filteredPurchases = List.from(allPurchases);
        loading = false;
        errorMessage = null;
      });
    } catch (e) {
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
              p.date.contains(query) ||
              p.vendor.toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (_sortColumnIndex != null) {
        sortPurchases(_sortColumnIndex!, _isAscending, updateState: false);
      }
    });
  }

  void addPurchase(Purchase purchase) {
    setState(() {
      allPurchases.add(purchase);
      filterSearch(searchController.text);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Purchase added successfully!')));
  }

  void sortPurchases(int columnIndex, bool ascending, {bool updateState = true}) {
    if (updateState) {
      setState(() {
        _sortColumnIndex = columnIndex;
        _isAscending = ascending;
      });
    }

    switch (columnIndex) {
      case 0: // Item Name
        filteredPurchases.sort((a, b) =>
            ascending ? a.itemName.compareTo(b.itemName) : b.itemName.compareTo(a.itemName));
        break;
      case 1: // Date
        filteredPurchases.sort((a, b) {
          DateTime dateA = DateTime.parse(a.date);
          DateTime dateB = DateTime.parse(b.date);
          return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        });
        break;
      case 2: // Purchaser Name
        filteredPurchases.sort((a, b) => ascending
            ? a.purchaserName.compareTo(b.purchaserName)
            : b.purchaserName.compareTo(a.purchaserName));
        break;
      case 3: // Vendor
        filteredPurchases.sort((a, b) =>
            ascending ? a.vendor.compareTo(b.vendor) : b.vendor.compareTo(a.vendor));
        break;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Purchase Log")),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            TextField(
                              controller: searchController,
                              onChanged: filterSearch,
                              decoration: InputDecoration(
                                hintText: "Search by item, purchaser, date, or vendor...",
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
                                      child: SingleChildScrollView(
                                        child: DataTable(
                                          sortColumnIndex: _sortColumnIndex,
                                          sortAscending: _isAscending,
                                          columns: [
                                            DataColumn(
                                              label: const Text("Item Name"),
                                              onSort: (columnIndex, ascending) {
                                                sortPurchases(columnIndex, ascending);
                                              },
                                            ),
                                            DataColumn(
                                              label: const Text("Date"),
                                              onSort: (columnIndex, ascending) {
                                                sortPurchases(columnIndex, ascending);
                                              },
                                            ),
                                            DataColumn(
                                              label: const Text("Purchaser Name"),
                                              onSort: (columnIndex, ascending) {
                                                sortPurchases(columnIndex, ascending);
                                              },
                                            ),
                                            DataColumn(
                                              label: const Text("Vendor"),
                                              onSort: (columnIndex, ascending) {
                                                sortPurchases(columnIndex, ascending);
                                              },
                                            ),
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
                                                    DataCell(
                                                      Text(purchase.vendor),
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPurchasePage(),
                              ),
                            );
                            if (result != null && result is Purchase) {
                              addPurchase(result);
                            }
                          },
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade300,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 48,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Log a Purchase',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class AddPurchasePage extends StatefulWidget {
  const AddPurchasePage({super.key});

  @override
  State<AddPurchasePage> createState() => _AddPurchasePageState();
}

class _AddPurchasePageState extends State<AddPurchasePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController purchaserNameController = TextEditingController();
  final TextEditingController vendorController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  
  List<String> uploadedFiles = [];
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        uploadedFiles.add(result.files.single.name);
      });
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void submitForm() {
    if (_formKey.currentState!.validate()) {
      final purchase = Purchase(
        itemName: itemNameController.text,
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
        timeLogged: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        purchaserName: purchaserNameController.text,
        vendor: vendorController.text,
        price: double.parse(priceController.text),
        details: detailsController.text,
        uploadedFiles: uploadedFiles,
      );
      
      Navigator.pop(context, purchase);
    }
  }

  @override
  void dispose() {
    itemNameController.dispose();
    purchaserNameController.dispose();
    vendorController.dispose();
    priceController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a Purchase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: purchaserNameController,
                decoration: const InputDecoration(
                  labelText: 'Purchaser Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter purchaser name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: vendorController,
                decoration: const InputDecoration(
                  labelText: 'Vendor',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vendor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: detailsController,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Uploaded Files:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (uploadedFiles.isEmpty)
                const Text('No files uploaded')
              else
                ...uploadedFiles.map(
                  (file) => ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(file),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          uploadedFiles.remove(file);
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload PDF'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Submit Purchase',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PurchaseDetailPage extends StatelessWidget {
  final Purchase purchase;

  const PurchaseDetailPage({super.key, required this.purchase});

  Future<void> openPdf(String fileName) async {
    print('Opening PDF: $fileName');
    final Uri pdfUri = Uri.parse('https://resume-portfolio-ffb8e.web.app/Travel_Gen.pdf'); //random pdf to test with
    if (await canLaunchUrl(pdfUri)) {
    await launchUrl(pdfUri);
    }
  }

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
                (file) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(file),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      openPdf(file);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opened $file')),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}