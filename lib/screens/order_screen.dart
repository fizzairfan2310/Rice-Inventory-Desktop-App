import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdda_project/constants.dart';
import 'dart:convert';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> orders = [];
  bool isLoading = false;
  String? errorMessage;

  final _customerNameController = TextEditingController();
  final _itemOrderedController = TextEditingController();
  final _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost/stockify_api/get_orders.php'),
      );

      print('Raw response: ${response.body}');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            orders = data['orders'];
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

  Future<void> createOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final response = await http.post(
          Uri.parse('http://localhost/stockify_api/create_order.php'),
          body: {
            'customer_name': _customerNameController.text.trim(),
            'item_ordered': _itemOrderedController.text.trim(),
            'quantity': _quantityController.text.trim(),
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
            _customerNameController.clear();
            _itemOrderedController.clear();
            _quantityController.clear();
            fetchOrders();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order added successfully')),
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

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/stockify_api/update_order_status.php'),
        body: {
          'order_id': orderId.toString(),
          'status': newStatus,
        },
      );

      print('Update status response: ${response.body}');
      print('Update status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          fetchOrders();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order status updated to $newStatus')),
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

  Future<void> deleteOrder(int orderId) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/stockify_api/delete_order.php'),
        body: {
          'order_id': orderId.toString(),
        },
      );

      print('Delete response: ${response.body}');
      print('Delete status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          fetchOrders();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order deleted successfully')),
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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '🛒 Order Management',
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
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter customer name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _itemOrderedController,
                    decoration: InputDecoration(
                      labelText: 'Item Ordered',
                      prefixIcon: const Icon(Icons.inventory),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'Enter item ordered' : null,
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
                  ElevatedButton(
                    onPressed: isLoading ? null : createOrder,
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
                            'Add Order',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red))
            else if (orders.isEmpty)
              const Text('No orders found')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderId =
                        int.tryParse(order['order_id'].toString()) ?? 0;
                    final status = order['status'].toString().toLowerCase();
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
                                    '${order['item_ordered']} (${order['quantity']})',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text('Customer: ${order['customer_name']}'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: orderId > 0
                                  ? () =>
                                      updateOrderStatus(orderId, 'completed')
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: status == 'completed'
                                    ? Colors.green
                                    : Colors.grey,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(10),
                              ),
                              child:
                                  const Icon(Icons.check, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: orderId > 0
                                  ? () => updateOrderStatus(orderId, 'pending')
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: status == 'pending'
                                    ? Colors.orange
                                    : Colors.grey,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(10),
                              ),
                              child: const Icon(Icons.hourglass_empty,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: orderId > 0
                                  ? () => deleteOrder(orderId)
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
