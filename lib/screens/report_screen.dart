import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdda_project/constants.dart';
import 'dart:convert';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<dynamic> reports = [];
  bool isLoading = false;
  String? errorMessage;

  final _reportTypeController = TextEditingController();
  final _reportDetailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost/stockify_api/get_reports.php'),
      );

      print('Raw response: ${response.body}');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            reports = data['reports'];
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

  Future<void> createReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final response = await http.post(
          Uri.parse('http://localhost/stockify_api/create_report.php'),
          body: {
            'report_type': _reportTypeController.text.trim(),
            'report_details': _reportDetailsController.text.trim(),
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
            _reportTypeController.clear();
            _reportDetailsController.clear();
            fetchReports();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report added successfully')),
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

  Future<void> deleteReport(int reportId) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost/stockify_api/delete_report.php'),
        body: {
          'report_id': reportId.toString(),
        },
      );

      print('Delete response: ${response.body}');
      print('Delete status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          fetchReports();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted successfully')),
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
        title: const Text(
          '📋 Report Management',
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
                    controller: _reportTypeController,
                    decoration: InputDecoration(
                      labelText: 'Report Type (sales/inventory/supplier)',
                      prefixIcon: const Icon(Icons.report),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) => val!.isEmpty
                        ? 'Enter report type'
                        : !['sales', 'inventory', 'supplier']
                                .contains(val.toLowerCase())
                            ? 'Invalid report type'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _reportDetailsController,
                    decoration: InputDecoration(
                      labelText: 'Report Details',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                    validator: (val) =>
                        val!.isEmpty ? 'Enter report details' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : createReport,
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
                            'Add Report',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Report List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red))
            else if (reports.isEmpty)
              const Text('No reports found')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final reportId =
                        int.tryParse(report['report_id'].toString()) ?? 0;
                    print('Report ID for ${report['report_type']}: $reportId');
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
                                    'Type: ${report['report_type']}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Details: ${report['report_details']} | Date: ${report['created_at']}',
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: reportId > 0
                                  ? () {
                                      print(
                                          'Delete button pressed for reportId: $reportId');
                                      deleteReport(reportId);
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
