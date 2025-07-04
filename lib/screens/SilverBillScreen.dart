import 'package:flutter/material.dart';

class SilverBillScreen extends StatefulWidget {
  @override
  _SilverBillScreenState createState() => _SilverBillScreenState();
}

class _SilverBillScreenState extends State<SilverBillScreen> {
  // Gold types and item descriptions
  String selectedType = '916';

  String selectedDescription = 'Chain';
  final List<String> descriptions = ['Chain', 'Bracelet', 'Necklace', 'Ring', 'Earring'];

  // Controllers
  final weightController = TextEditingController();
  final countController = TextEditingController();
  final amountController = TextEditingController();
  final valueAddedController = TextEditingController();

  @override
  void dispose() {
    weightController.dispose();
    countController.dispose();
    amountController.dispose();
    valueAddedController.dispose();
    super.dispose();
  }

  void submitInvoice() {
    final data = {
      "type": selectedType,
      "description": selectedDescription,
      "weight": weightController.text,
      "count": countController.text,
      "amount": amountController.text,
      "valueAdded": valueAddedController.text,
    };

    print(data); // Replace with actual saving logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Invoice Entry")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Gold Type Dropdown
              SizedBox(height: 10),

              // Description Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Description'),
                value: selectedDescription,
                items: descriptions.map((desc) {
                  return DropdownMenuItem(
                    value: desc,
                    child: Text(desc),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDescription = value!;
                  });
                },
              ),
              SizedBox(height: 10),

              // Weight
              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (grams)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              // Count
              TextFormField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Count',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              // Actual Amount
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Actual Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              // Value Added
              TextFormField(
                controller: valueAddedController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Value Added (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Submit Button
              ElevatedButton.icon(
                onPressed: submitInvoice,
                icon: Icon(Icons.save),
                label: Text("Save Invoice"),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
