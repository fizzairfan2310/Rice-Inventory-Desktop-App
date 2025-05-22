import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdda_project/constants.dart';
import 'dart:convert';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  _SupplierScreenState createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  List<dynamic> suppliers = [];
  bool isLoading = false;
  String? errorMessage;

  final _supplierNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost/stockify_api/get_suppliers.php'),
      );

      print('Raw response: ${response.body}');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            suppliers = data['suppliers'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> createSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Debug: Log the data being sent
      final supplierName = _supplierNameController.text.trim();
      final contactEmail = _contactEmailController.text.trim();
      final phone = _phoneController.text.trim();
      print('Data being sent:');
      print('Supplier Name: "$supplierName"');
      print('Contact Email: "$contactEmail"');
      print('Phone: "$phone"');

      try {
        final response = await http.post(
          Uri.parse('http://localhost/stockify_api/create_supplier.php'),
          body: {
            'supplier_name': supplierName,
            'contact_email': contactEmail,
            'phone': phone,
          },
        );

        print('Raw response: ${response.body}');
        print('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            isLoading = false;
          });

          if (data['success']) {
            _supplierNameController.clear();
            _contactEmailController.clear();
            _phoneController.clear();
            fetchSuppliers();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Supplier added successfully')),
            );
          } else {
            setState(() {
              errorMessage = data['message'];
            });
          }
        } else {
          setState(() {
            errorMessage = 'Server error: ${response.statusCode}';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
        print('Error: $e');
      }
    }
  }

  Future<void> deleteSupplier(int supplierId) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/stockify_api/delete_supplier.php'),
        body: {
          'supplier_id': supplierId.toString(),
        },
      );

      print('Delete response: ${response.body}');
      print('Delete status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          fetchSuppliers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier deleted successfully')),
          );
        } else {
          setState(() {
            errorMessage = data['message'];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🔗 Supplier Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _supplierNameController,
                    decoration: InputDecoration(
                      labelText: 'Supplier Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter supplier name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _contactEmailController,
                    decoration: InputDecoration(
                      labelText: 'Contact Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        val!.isEmpty ? 'Enter contact email' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone (optional)',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : createSupplier,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.kPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Add Supplier',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Supplier List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red))
            else if (suppliers.isEmpty)
              const Text('No suppliers found')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    final supplierId =
                        int.tryParse(supplier['supplier_id'].toString()) ?? 0;
                    print(
                        'Supplier ID for ${supplier['supplier_name']}: $supplierId');
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Supplier: ${supplier['supplier_name']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Email: ${supplier['contact_email']} | Phone: ${supplier['phone'] ?? 'N/A'} | Date: ${supplier['created_at']}',
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: supplierId > 0
                                  ? () {
                                      print(
                                          'Delete button pressed for supplierId: $supplierId');
                                      deleteSupplier(supplierId);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(10),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              child:
                                  const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
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
