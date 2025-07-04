import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final typeCtrl = TextEditingController();

  void handleAddProduct() async {
    final String name = nameCtrl.text.trim();
    final double? price = double.tryParse(priceCtrl.text.trim());
    final double? weight = double.tryParse(weightCtrl.text.trim());
    final String type = typeCtrl.text.trim();

    if (name.isEmpty || price == null || weight == null || type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': price,
        'weight': weight,
        'type': type,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product added successfully")),
      );

      nameCtrl.clear();
      priceCtrl.clear();
      weightCtrl.clear();
      typeCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _deleteProduct(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete product?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text("Delete")),
        ],
      ),
    );
    if (ok != true) return;

    await FirebaseFirestore.instance.collection('products').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product deleted")),
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final nameC   = TextEditingController(text: data['name']);
    final priceC  = TextEditingController(text: data['price'].toString());
    final weightC = TextEditingController(text: data['weight'].toString());
    final typeC   = TextEditingController(text: data['type']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildDialogTF(nameC, "Name"),
              _buildDialogTF(priceC, "Price", TextInputType.number),
              _buildDialogTF(weightC, "Weight", TextInputType.number),
              _buildDialogTF(typeC, "Type"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(docId).update({
                'name'  : nameC.text.trim(),
                'price' : double.tryParse(priceC.text.trim()) ?? 0,
                'weight': double.tryParse(weightC.text.trim()) ?? 0,
                'type'  : typeC.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Product updated")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTF(TextEditingController c, String label, [TextInputType? k]) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          keyboardType: k,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    weightCtrl.dispose();
    typeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f4f4),
      appBar: AppBar(
        title: const Text("🛒 Product Management"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Add New Product",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(nameCtrl, "Product Name"),
                    _buildTextField(priceCtrl, "Price", inputType: TextInputType.number),
                    _buildTextField(weightCtrl, "Weight (grams)", inputType: TextInputType.number),
                    _buildTextField(typeCtrl, "Type (e.g. Ring, Necklace)"),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: handleAddProduct,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Product"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Text("No products yet"),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snap.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = snap.data!.docs[i];
                    final data = doc.data();
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(data['name']),
                      subtitle: Text("${data['type']} • ${data['weight']} g • ₹${data['price']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => _showEditDialog(doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteProduct(doc.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? inputType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: inputType ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}
