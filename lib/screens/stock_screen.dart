import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdda_project/constants.dart';
import 'dart:convert';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<dynamic> stock = [];
  bool isLoading = false;
  String? errorMessage;

  final _stockNameController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedType = 'Raw'; // Default value for dropdown
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchStock();
  }

  Future<void> fetchStock() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost/stockify_api/get_stock.php'),
      );

      print('Raw response: ${response.body}');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          setState(() {
            errorMessage = 'Empty response from server';
            isLoading = false;
          });
          return;
        }

        try {
          final data = jsonDecode(response.body);
          print('Parsed data: $data');
          if (data['success']) {
            setState(() {
              stock = data['stock'];
              isLoading = false;
            });
          } else {
            setState(() {
              errorMessage = data['message'] ?? 'Unknown error';
              isLoading = false;
            });
          }
        } catch (e) {
          setState(() {
            errorMessage = 'Invalid JSON response: $e';
            isLoading = false;
          });
          print('JSON parsing error: $e');
        }
      } else {
        setState(() {
          errorMessage =
              'Server error: ${response.statusCode} - ${response.body}';
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

  Future<void> createStock() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final response = await http.post(
          Uri.parse('http://localhost/stockify_api/create_stock.php'),
          body: {
            'item_name': _stockNameController.text.trim(),
            'quantity': _quantityController.text.trim(),
            'type': _selectedType!.toLowerCase(),
          },
        );

        print('Create stock response: ${response.body}');
        print('Create stock status: ${response.statusCode}');

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            setState(() {
              isLoading = false;
            });

            if (data['success']) {
              _stockNameController.clear();
              _quantityController.clear();
              _selectedType = 'Raw';
              fetchStock();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock item added successfully')),
              );
            } else {
              setState(() {
                errorMessage = data['message'] ?? 'Unknown error';
              });
            }
          } catch (e) {
            setState(() {
              errorMessage = 'Invalid JSON response: $e';
              isLoading = false;
            });
            print('JSON parsing error: $e');
          }
        } else {
          setState(() {
            errorMessage =
                'Server error: ${response.statusCode} - ${response.body}';
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

  Future<void> deleteStock(int stockId) async {
    if (stockId <= 0) {
      print('Invalid stockId: $stockId');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/stockify_api/delete_stock.php'),
        body: {
          'stock_id': stockId.toString(),
        },
      );

      print('Delete response: ${response.body}');
      print('Delete status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success']) {
            fetchStock();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stock item deleted successfully')),
            );
          } else {
            setState(() {
              errorMessage = data['message'] ?? 'Unknown error';
              isLoading = false;
            });
          }
        } catch (e) {
          setState(() {
            errorMessage = 'Invalid JSON response: $e';
            isLoading = false;
          });
          print('JSON parsing error: $e');
        }
      } else {
        setState(() {
          errorMessage =
              'Server error: ${response.statusCode} - ${response.body}';
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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '📦 Stock Management',
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
                    controller: _stockNameController,
                    decoration: InputDecoration(
                      labelText: 'Stock Name',
                      prefixIcon: const Icon(Icons.inventory),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter stock name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: const Icon(Icons.format_list_numbered),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => val!.isEmpty ? 'Enter quantity' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['Raw', 'Processed']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                    validator: (val) => val == null ? 'Select a type' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : createStock,
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
                            'Add Stock',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Stock List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red))
            else if (stock.isEmpty)
              const Text('No stock items found')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: stock.length,
                  itemBuilder: (context, index) {
                    final item = stock[index];
                    final stockId =
                        int.tryParse(item['stock_id'].toString()) ?? 0;
                    print('Stock item data: $item');
                    print('Stock ID for item ${item['item_name']}: $stockId');
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
                                    '${item['item_name']} (${item['type']})',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text('Quantity: ${item['quantity']}'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: stockId > 0
                                  ? () {
                                      print(
                                          'Delete button pressed for stockId: $stockId');
                                      deleteStock(stockId);
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
