import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String goldPrice="50000";
  String silverPrice="20000";
  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  Future<void> fetchRates() async {
    try {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('rate').doc('rate').get();

      if (doc.exists) {
        setState(() {
          goldPrice = doc['gold'].toString();
          silverPrice = doc['silver'].toString();
        });
      } else {
        setState(() {
          goldPrice = "Not found";
          silverPrice = "Not found";
        });
      }
    } catch (e) {
      print("Error fetching rates: $e");
      setState(() {
        goldPrice = "Error";
        silverPrice = "Error";
      });
    }
  }
  Future<void> updateRate(String field, String newValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('rate')
          .doc('rate')
          .update({field: double.parse(newValue)});
      fetchRates(); // Refresh UI after update
    } catch (e) {
      print("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $field rate')),
      );
    }
  }
  void showUpdateDialog({
    required String title,
    required String fieldName,
    required String currentValue,
  }) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update $title Rate"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Enter new $title rate",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await updateRate(fieldName, controller.text); // update function
              Navigator.pop(context); // close the small screen
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xFF0D4C4A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, Admin",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            // Stat Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Total Sales Today", "₹1,25,000", Icons.currency_rupee),
                _buildStatCard("Invoices Today", "15", Icons.receipt_long),
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: Colors.teal.withOpacity(0.3),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Icon(Icons.price_change, size: 40, color: Colors.teal),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "Gold Price: ₹ $goldPrice ",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  showUpdateDialog(
                                    title: "Gold",
                                    fieldName: "gold",
                                    currentValue: goldPrice,
                                  );
                                // your edit function here
                              },
                              icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                              tooltip: "Edit Gold Price",
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "Silver Price: ₹ $silverPrice ",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                showUpdateDialog(
                                    title: "Silver",
                                    fieldName: "silver",
                                    currentValue: silverPrice,);
                                // your edit function here
                              },
                              icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                              tooltip: "Edit Silver Price",
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )

              ],
            ),

            const SizedBox(height: 30),


            // Quick Navigation Buttons
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildNavButton(context, "Products", Icons.inventory, '/products'),
                _buildNavButton(context, "Customers", Icons.people, '/customersDetails'),
                _buildNavButton(context, "Invoice History", Icons.history, '/invoiceHistory'),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/GoldbillGenerate');
                  },
                  child: Card(
                    elevation: 5,
                    color: Color(0xFFFFD700), // Silver color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            "GOLD",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                     Navigator.pushNamed(context, '/SilverbillGenerate');
                  },
                  child: Card(
                    elevation: 5,
                    color: Color(0xFFC0C0C0), // Silver color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            "SILVER",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                )


              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 5,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.teal),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String title, IconData icon, String route) {
    return ElevatedButton.icon(
      onPressed: () {
        // For now just show snackbar
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Navigate to $title")));
        Navigator.pushNamed(context, route);
      },
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );;
  }
}
