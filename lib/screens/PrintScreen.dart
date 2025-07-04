import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PrintInvoiceScreen extends StatefulWidget {
  final List<List<String>> invoice;
  final String entryType;

  const PrintInvoiceScreen({
    super.key,
    required this.invoice,
    required this.entryType,
  });

  @override
  State<PrintInvoiceScreen> createState() => _PrintInvoiceScreenState();
}

class _PrintInvoiceScreenState extends State<PrintInvoiceScreen> {
  final customerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  double getGrandTotal() {
    double total = 0;
    for (var item in widget.invoice) {
      total += double.tryParse(item[3]) ?? 0;
    }
    return total;
  }

  Future<void> saveAndPrintInvoice() async {
    final name = customerNameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();

    if (name.isEmpty || phone.length < 10 || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all customer details correctly")),
      );
      return;
    }

    if (widget.invoice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice has no items")),
      );
      return;
    }

    try {
      final customerRef = await FirebaseFirestore.instance.collection('customers').add({
        'name': name,
        'phone': phone,
        'address': address,
        'createdAt': Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('invoices').add({
        'customerId': customerRef.id,
        'customerName': name,
        'phone': phone,
        'address': address,
        'entryType': widget.entryType,
        'items': widget.invoice.map((e) => {
          'qtyOrWeight': e[0],
          'valueAdded': e[1],
          'amount': e[2],
          'total': e[3],
        }).toList(),
        'grandTotal': getGrandTotal(),
        'createdAt': Timestamp.now(),
      });

      final pdf = await generatePdfInvoice(name, phone, address, widget.invoice, widget.entryType);
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Invoice saved & ready for print")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<pw.Document> generatePdfInvoice(
      String name,
      String phone,
      String address,
      List<List<String>> invoice,
      String entryType,
      ) async {
    final pdf = pw.Document();
    final total = getGrandTotal();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("💎 Gold Invoice", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Customer: $name"),
            pw.Text("Phone   : $phone"),
            pw.Text("Address : $address"),
            pw.Text("Entry Type: $entryType"),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              headers: ['Qty/Weight', 'Value Added', 'Amount', 'Total'],
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              data: invoice.map((e) => [e[0], "₹${e[1]}", "₹${e[2]}", "₹${e[3]}"]).toList(),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Grand Total: ₹${total.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text("Thank you for your business!",
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = getGrandTotal();
    return Scaffold(
      appBar: AppBar(title: const Text("🧾 Print Invoice")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Address", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text("Invoice Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.invoice.length,
                itemBuilder: (context, index) {
                  final item = widget.invoice[index];
                  return Card(
                    child: ListTile(
                      title: Text("Qty/Weight: ${item[0]}"),
                      subtitle: Text(
                        "Value Added: ₹${item[1]}\nAmount: ₹${item[2]}\nTotal: ₹${item[3]}",
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Grand Total: ₹${total.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveAndPrintInvoice,
                icon: const Icon(Icons.print),
                label: const Text("Save & Print Invoice"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
