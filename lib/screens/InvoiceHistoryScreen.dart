import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  String filterType = 'All';
  final List<String> filterOptions = ['All', 'count', 'weight'];
  final nameController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📜 Invoice History")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Entry Type:"),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: filterType,
                  items: filterOptions
                      .map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => filterType = val!),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Search by Customer Name",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    nameController.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: const Text("Pick Date Range"),
                ),
                const SizedBox(width: 10),
                if (startDate != null && endDate != null)
                  Text(
                    "${DateFormat('dd-MM-yyyy').format(startDate!)} → ${DateFormat('dd-MM-yyyy').format(endDate!)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('invoices')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final filteredDocs = docs.where((doc) {
                    final type = doc['entryType'];
                    final name = (doc['customerName'] ?? '').toString().toLowerCase();
                    final queryName = nameController.text.toLowerCase();
                    final createdAt = (doc['createdAt'] as Timestamp).toDate();

                    final matchesType = filterType == 'All' || type == filterType;
                    final matchesName = queryName.isEmpty || name.contains(queryName);
                    final matchesDate = (startDate == null || endDate == null)
                        ? true
                        : (createdAt.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                        createdAt.isBefore(endDate!.add(const Duration(days: 1))));

                    return matchesType && matchesName && matchesDate;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text("No invoices found."));
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final items = List<Map<String, dynamic>>.from(doc['items']);
                      final total = doc['grandTotal'] ?? '0';
                      final name = doc['customerName'] ?? 'Unknown';
                      final entryType = doc['entryType'];
                      final createdAt = (doc['createdAt'] as Timestamp).toDate();
                      final formattedDate = DateFormat('dd-MM-yyyy').format(createdAt);

                      return Card(
                        child: ListTile(
                          title: Text("Customer: $name"),
                          subtitle: Text("Type: $entryType | Date: $formattedDate\nTotal: ₹$total"),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Invoice Details"),
                                content: SizedBox(
                                  height: 300,
                                  width: 300,
                                  child: ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (_, i) => ListTile(
                                      title: Text("Qty/Weight: ${items[i]['qtyOrWeight']}"),
                                      subtitle: Text(
                                          "Added: ₹${items[i]['valueAdded']} | Amount: ₹${items[i]['amount']} | Total: ₹${items[i]['total']}"),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close"),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
