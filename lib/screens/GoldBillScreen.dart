import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'PrintScreen.dart';

class GoldBillScreen extends StatefulWidget {
  @override
  _GoldBillScreenState createState() => _GoldBillScreenState();
}

class _GoldBillScreenState extends State<GoldBillScreen> {
  late String goldPrice = '';
  double ratePerGram = 0.0;

  List<List<String>> invoice = [];
  List<String> productNames = [];
  Map<String, double> productPriceMap = {};

  // Dropdown values
  String selectedType = '916';
  final List<String> goldTypes = ['916', 'Regular'];

  String entryType = 'count';
  final List<String> entryTypes = ['count', 'weight'];

  String? selectedProduct;

  // Controllers
  final weightController = TextEditingController();
  final countController = TextEditingController();
  final amountController = TextEditingController();
  final valueAddedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRates();
    fetchProducts();

    countController.addListener(() {
      if (entryType != 'count' || selectedProduct == null) return;
      final count = double.tryParse(countController.text);
      final productPrice = productPriceMap[selectedProduct] ?? 0;
      if (count != null) {
        final total = count * productPrice;
        amountController.text = total.toStringAsFixed(2);
      }
    });

    weightController.addListener(() {
      if (entryType != 'weight') return;
      final weight = double.tryParse(weightController.text);
      if (weight != null && ratePerGram > 0) {
        final total = weight * ratePerGram;
        amountController.text = total.toStringAsFixed(2);
      }
    });
  }

  Future<void> fetchRates() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('rate').doc('rate').get();
      if (doc.exists) {
        setState(() {
          goldPrice = doc['gold'].toString();
          int rate = int.tryParse(goldPrice) ?? 0;
          ratePerGram = rate / 8;
        });
      } else {
        goldPrice = "Not found";
      }
    } catch (e) {
      print("Error fetching rates: $e");
      goldPrice = "Error";
    }
  }

  Future<void> fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      for (var doc in snapshot.docs) {
        final name = doc['name'];
        final price = doc['price']?.toDouble() ?? 0.0;
        productNames.add(name);
        productPriceMap[name] = price;
      }
      setState(() {
        selectedProduct = productNames.isNotEmpty ? productNames.first : null;
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  void addToInvoice({required String qtyOrWeight}) {
    final valueAdded = double.tryParse(valueAddedController.text) ?? 0.0;
    final amount = double.tryParse(amountController.text) ?? 0.0;
    final totalAmount = valueAdded + amount;

    setState(() {
      invoice.add([
        qtyOrWeight,
        valueAdded.toStringAsFixed(2),
        amount.toStringAsFixed(2),
        totalAmount.toStringAsFixed(2),
        selectedProduct ?? '',
      ]);

      weightController.clear();
      countController.clear();
      amountController.clear();
      valueAddedController.clear();
    });
  }

  void saveInvoice() async {
    try {
      final invoiceData = invoice.map((item) => {
        'qty_or_weight': item[0],
        'value_added': item[1],
        'amount': item[2],
        'total': item[3],
        'product': item[4],
      }).toList();

      await FirebaseFirestore.instance.collection('invoices').add({
        'timestamp': Timestamp.now(),
        'items': invoiceData,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invoice saved!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save invoice: $e")));
    }
  }

  Widget getFormFields() {
    if (entryType == 'count') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Product'),
            value: selectedProduct,
            items: productNames.map((name) {
              return DropdownMenuItem(value: name, child: Text(name));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedProduct = value;
                final count = double.tryParse(countController.text);
                if (count != null && value != null) {
                  final price = productPriceMap[value] ?? 0;
                  final total = count * price;
                  amountController.text = total.toStringAsFixed(2);
                }
              });
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: countController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Count', border: OutlineInputBorder()),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: amountController,
            readOnly: true,
            decoration: InputDecoration(labelText: 'Actual Amount (₹)', border: OutlineInputBorder()),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: valueAddedController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Value Added (₹)', border: OutlineInputBorder()),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (countController.text.isNotEmpty) {
                addToInvoice(qtyOrWeight: countController.text);
              }
            },
            icon: Icon(Icons.save),
            label: Text("Add"),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Gold Type'),
            value: selectedType,
            items: goldTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedType = value!;
              });
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Weight (grams)', border: OutlineInputBorder()),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: amountController,
            readOnly: true,
            decoration: InputDecoration(labelText: 'Actual Amount (₹)', border: OutlineInputBorder()),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: valueAddedController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Value Added (₹)', border: OutlineInputBorder()),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (weightController.text.isNotEmpty) {
                addToInvoice(qtyOrWeight: weightController.text);
              }
            },
            icon: Icon(Icons.save),
            label: Text("Add"),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    weightController.dispose();
    countController.dispose();
    amountController.dispose();
    valueAddedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gold Invoice Entry")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Entry Type'),
                value: entryType,
                items: entryTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    entryType = value!;
                  });
                },
              ),
              SizedBox(height: 10),
              getFormFields(),
              SizedBox(height: 20),
              Divider(),
              Text("Invoice List", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ListView.builder(
                itemCount: invoice.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Text("${index + 1}"),
                      title: Text("Qty/Weight: ${invoice[index][0]} - ${invoice[index][4]}"),
                      subtitle: Text(
                        "Value Added: ₹${invoice[index][1]}\nAmount: ₹${invoice[index][2]}\nTotal: ₹${invoice[index][3]}",
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  if (invoice.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invoice is empty")),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrintInvoiceScreen(invoice: invoice, entryType: entryType),
                    ),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text("Save & Print Invoice"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}