import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:sdda_project/constants.dart';
import 'dart:convert';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  _OwnerDashboardState createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int newItems = 0;
  int newOrders = 0;
  int refunds = 0;
  int messages = 0;
  int groups = 0;
  int lowStockItems = 0;
  int refundedItems = 0;
  double totalStockValue = 0.0;
  int expiringStock = 0;
  double totalRevenue = 0.0;
  Map<String, int> pendingOrdersByCustomer = {};
  Map<String, int> stockBySupplier = {};
  Map<String, int> stockByCategory = {};
  List<String> alerts = [];
  List<Map<String, String>> recentTransactions = [];
  Map<String, int> stores = {
    'Manchester': 0,
    'Yorkshire': 0,
    'Hull': 0,
    'Leicester': 0,
  };
  List<double> salesGraphData = [
    0,
    0,
    0,
    0
  ]; // Confirmed, Packed, Refunded, Shipped
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final stockResponse = await http.get(
        Uri.parse('http://localhost/stockify_api/get_stock.php'),
      );
      print('Stock response: ${stockResponse.body}');
      print('Stock status: ${stockResponse.statusCode}');
      if (stockResponse.statusCode == 200) {
        final stockData = jsonDecode(stockResponse.body);
        if (stockData['success']) {
          List stockItems = stockData['stock'];
          newItems = stockItems.length;
          lowStockItems = stockItems
              .where((item) => _parseInt(item['quantity']) < 10)
              .length;

          totalStockValue = stockItems.fold(
              0.0,
              (sum, item) =>
                  sum +
                  (_parseInt(item['quantity']) * _parseDouble(item['price'])));

          DateTime now = DateTime.now();
          expiringStock = stockItems.where((item) {
            if (item['expiration_date'] == null) return false;
            try {
              DateTime expiry = DateTime.parse(item['expiration_date']);
              return expiry.difference(now).inDays <= 30 && expiry.isAfter(now);
            } catch (e) {
              return false;
            }
          }).length;

          stockItems.forEach((item) {
            String supplierId = item['supplier_id']?.toString() ?? 'Unknown';
            stockBySupplier[supplierId] = (stockBySupplier[supplierId] ?? 0) +
                _parseInt(item['quantity']);
          });

          stockItems.forEach((item) {
            String category = item['category'] ?? 'Unknown';
            stockByCategory[category] =
                (stockByCategory[category] ?? 0) + _parseInt(item['quantity']);
          });

          int totalItems = stockItems.length;
          stores['Manchester'] = (totalItems * 0.35).round();
          stores['Yorkshire'] = (totalItems * 0.33).round();
          stores['Hull'] = (totalItems * 0.12).round();
          stores['Leicester'] = totalItems -
              stores['Manchester']! -
              stores['Yorkshire']! -
              stores['Hull']!;

          stockItems.take(3).forEach((item) {
            recentTransactions.add({
              'type': 'Stock Added',
              'details':
                  '${item['item_name']}: ${_parseInt(item['quantity'])} units',
            });
          });

          if (lowStockItems > 0) {
            alerts.add('$lowStockItems items are low in stock!');
          }
          if (expiringStock > 0) {
            alerts.add('$expiringStock items are expiring soon!');
          }
        }
      }

      final ordersResponse = await http.get(
        Uri.parse('http://localhost/stockify_api/get_orders.php'),
      );
      print('Orders response: ${ordersResponse.body}');
      print('Orders status: ${ordersResponse.statusCode}');
      if (ordersResponse.statusCode == 200) {
        final ordersData = jsonDecode(ordersResponse.body);
        if (ordersData['success']) {
          List orders = ordersData['orders'];
          newOrders = orders.length;
          refunds = orders
              .where((order) => order['status'].toLowerCase() == 'cancelled')
              .length;

          int pending = orders
              .where((order) => order['status'].toLowerCase() == 'pending')
              .length;
          int completed = orders
              .where((order) => order['status'].toLowerCase() == 'completed')
              .length;
          int cancelled = refunds;
          salesGraphData = [
            pending.toDouble(),
            completed.toDouble(),
            cancelled.toDouble(),
            0.0
          ];

          totalRevenue = orders.fold(
              0.0, (sum, order) => sum + _parseDouble(order['total_amount']));

          orders
              .where((order) => order['status'].toLowerCase() == 'pending')
              .forEach((order) {
            String customer = order['customer_name'] ?? 'Unknown';
            pendingOrdersByCustomer[customer] =
                (pendingOrdersByCustomer[customer] ?? 0) + 1;
          });

          orders
              .where((order) => order['status'].toLowerCase() == 'completed')
              .take(3)
              .forEach((order) {
            recentTransactions.add({
              'type': 'Order Completed',
              'details':
                  '${order['customer_name']}: \$${order['total_amount']}',
            });
          });

          refundedItems = cancelled;

          if (pending > 5) {
            alerts.add('$pending pending orders need attention!');
          }
        }
      }

      final reportsResponse = await http.get(
        Uri.parse('http://localhost/stockify_api/get_reports.php'),
      );
      print('Reports response: ${reportsResponse.body}');
      print('Reports status: ${reportsResponse.statusCode}');
      if (reportsResponse.statusCode == 200) {
        final reportsData = jsonDecode(reportsResponse.body);
        if (reportsData['success']) {
          messages = (reportsData['reports'] as List).length;
        }
      }

      final suppliersResponse = await http.get(
        Uri.parse('http://localhost/stockify_api/get_suppliers.php'),
      );
      print('Suppliers response: ${suppliersResponse.body}');
      print('Suppliers status: ${suppliersResponse.statusCode}');
      if (suppliersResponse.statusCode == 200) {
        final suppliersData = jsonDecode(suppliersResponse.body);
        if (suppliersData['success']) {
          groups = (suppliersData['suppliers'] as List).length;
          List suppliers = suppliersData['suppliers'];
          stockBySupplier =
              Map.fromEntries(stockBySupplier.entries.map((entry) {
            var supplier = suppliers.firstWhere(
                (s) => s['supplier_id'].toString() == entry.key,
                orElse: () => {'supplier_name': 'Unknown'});
            return MapEntry(supplier['supplier_name'], entry.value);
          }));
        }
      }

      setState(() {
        isLoading = false;
      });
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
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 220,
                  color: Constants.kPrimary,
                  child: Builder(
                    builder: (sidebarContext) => Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Positioned(
                                  top: 40,
                                  left: 20,
                                  child: Hero(
                                    tag: 'stockifyIcon',
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Positioned(
                                  top: 42,
                                  left: 65,
                                  child: Hero(
                                    tag: 'stockifyTitle',
                                    child: Text(
                                      'Stockify',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 50),
                            sidebarTile(sidebarContext, Icons.shopping_bag,
                                'Orders', '/orders'),
                            sidebarTile(sidebarContext, Icons.inventory,
                                'Stock', '/stock'),
                            sidebarTile(sidebarContext, Icons.local_shipping,
                                'Suppliers', '/suppliers'),
                            sidebarTile(sidebarContext, Icons.assessment,
                                'Reports', '/reports'),
                          ],
                        ),
                        Column(
                          children: [
                            const Divider(color: Colors.white24),
                            ListTile(
                              leading:
                                  const Icon(Icons.logout, color: Colors.white),
                              title: const Text('Logout',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 236,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : errorMessage != null
                                    ? Center(
                                        child: Text(
                                          errorMessage!,
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.grey.shade300,
                                                    blurRadius: 10)
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 10),
                                                const Text("Dashboard",
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                SizedBox(
                                                  width: 20,
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.search,
                                                            color: Colors.grey),
                                                        const SizedBox(
                                                            width: 10),
                                                        Expanded(
                                                          child: TextField(
                                                            decoration:
                                                                InputDecoration
                                                                    .collapsed(
                                                                        hintText:
                                                                            'Search'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 30),
                                                Icon(Icons.notifications_none,
                                                    color: Constants.kPrimary,
                                                    size: 28),
                                                const SizedBox(width: 20),
                                                Icon(Icons.person_outline,
                                                    color: Constants.kPrimary,
                                                    size: 28),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          SizedBox(
                                            height: 80,
                                            child: Center(
                                              child: ListView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 18.0),
                                                    child: Text(
                                                      'Recent Activity',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ),
                                                  SizedBox(width: 20),
                                                  summaryBox("NEW ITEMS",
                                                      newItems.toString()),
                                                  summaryBox("NEW ORDERS",
                                                      newOrders.toString()),
                                                  summaryBox("REFUNDS",
                                                      refunds.toString()),
                                                  summaryBox("MESSAGE",
                                                      messages.toString()),
                                                  summaryBox("GROUPS",
                                                      groups.toString()),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 200,
                                                  child: buildCard(
                                                    'Sales Graph',
                                                    BarChart(
                                                      BarChartData(
                                                        titlesData:
                                                            FlTitlesData(
                                                          bottomTitles:
                                                              AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                              showTitles: true,
                                                              getTitlesWidget:
                                                                  bottomTitles,
                                                            ),
                                                          ),
                                                          leftTitles:
                                                              AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                                    showTitles:
                                                                        false),
                                                          ),
                                                          rightTitles:
                                                              AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                                    showTitles:
                                                                        false),
                                                          ),
                                                          topTitles: AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                                    showTitles:
                                                                        false),
                                                          ),
                                                        ),
                                                        borderData:
                                                            FlBorderData(
                                                                show: false),
                                                        barGroups:
                                                            List.generate(
                                                          salesGraphData.length,
                                                          (index) =>
                                                              makeGroupData(
                                                                  index,
                                                                  salesGraphData[
                                                                      index]),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 200,
                                                  child: buildCard(
                                                    'Stock Numbers',
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Low stock items: $lowStockItems'),
                                                        const Text(
                                                            'Item categories: 6'),
                                                        Text(
                                                            'Refunded items: $refundedItems'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 200,
                                                  child: buildCard(
                                                    'Stores List',
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Manchester — ${stores['Manchester']} items'),
                                                        Text(
                                                            'Yorkshire — ${stores['Yorkshire']} items'),
                                                        Text(
                                                            'Hull — ${stores['Hull']} items'),
                                                        Text(
                                                            'Leicester — ${stores['Leicester']} items'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 200,
                                                  child: buildCard(
                                                    'Top Categories',
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: [
                                                        categoryBox(
                                                            Icons.rice_bowl,
                                                            'Basmati'),
                                                        categoryBox(
                                                            Icons.rice_bowl,
                                                            'Brown'),
                                                        categoryBox(
                                                            Icons.rice_bowl,
                                                            'Sella'),
                                                        categoryBox(
                                                            Icons.rice_bowl,
                                                            'Steam'),
                                                        categoryBox(
                                                            Icons.rice_bowl,
                                                            'White'),
                                                        categoryBox(
                                                            Icons.rice_bowl,
                                                            'Broken'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 150,
                                                  child: buildCard(
                                                    'Inventory Health',
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Total Stock Value: \$${totalStockValue.toStringAsFixed(2)}'),
                                                        Text(
                                                            'Expiring Stock: $expiringStock items'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 150,
                                                  child: buildCard(
                                                    'Order Insights',
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Total Revenue: \$${totalRevenue.toStringAsFixed(2)}'),
                                                        const SizedBox(
                                                            height: 4),
                                                        const Text(
                                                            'Pending Orders by Customer:'),
                                                        ...pendingOrdersByCustomer
                                                            .entries
                                                            .take(3)
                                                            .map((entry) => Text(
                                                                '${entry.key}: ${entry.value}')),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 150,
                                                  child: buildCard(
                                                    'Supplier Performance',
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                            'Top Suppliers by Stock:'),
                                                        ...stockBySupplier
                                                            .entries
                                                            .take(3)
                                                            .map((entry) => Text(
                                                                '${entry.key}: ${entry.value} units')),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 150,
                                                  child: buildCard(
                                                    'Alerts',
                                                    SingleChildScrollView(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: alerts.isEmpty
                                                            ? [
                                                                const Text(
                                                                    'No alerts')
                                                              ]
                                                            : alerts
                                                                .map((alert) => Text(
                                                                    alert,
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .red)))
                                                                .toList(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 150,
                                                  child: buildCard(
                                                    'Category Breakdown',
                                                    SingleChildScrollView(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: stockByCategory
                                                            .entries
                                                            .map((entry) => Text(
                                                                '${entry.key}: ${entry.value} units'))
                                                            .toList(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 150,
                                                  child: buildCard(
                                                    'Recent Transactions',
                                                    SingleChildScrollView(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: recentTransactions
                                                            .map((txn) => Text(
                                                                '${txn['type']}: ${txn['details']}'))
                                                            .toList(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(child: Container()),
                                              Expanded(child: Container()),
                                            ],
                                          ),
                                        ],
                                      ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sidebarTile(
      BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  Widget buildCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget summaryBox(String title, String value) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Constants.kPrimary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.kPrimary)),
          const SizedBox(height: 2),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget categoryBox(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Constants.kPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y, color: Constants.kPrimary, width: 10),
    ]);
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const titles = ['Confirmed', 'Packed', 'Refunded', 'Shipped'];
    const style = TextStyle(color: Colors.black, fontSize: 10);
    return SideTitleWidget(
      space: 4,
      meta: meta,
      child: Text(titles[value.toInt()], style: style),
    );
  }
}
