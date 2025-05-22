import 'package:flutter/material.dart';
import 'package:sdda_project/constants.dart';
import 'package:sdda_project/screens/login_screen.dart';
import 'package:sdda_project/screens/order_screen.dart';
import 'package:sdda_project/screens/owner_dashboard.dart';
import 'package:sdda_project/screens/register_screen.dart';
import 'package:sdda_project/screens/report_screen.dart';
import 'package:sdda_project/screens/splash_screen.dart';
import 'package:sdda_project/screens/stock_screen.dart';
import 'package:sdda_project/screens/supplier_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockify',
      theme: ThemeData(
        primarySwatch: Constants.kSwatchColor,
        primaryColor: Constants.kPrimary,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/': (context) => const OwnerDashboard(),
        '/orders': (context) => const OrderScreen(),
        '/stock': (context) => StockScreen(),
        '/suppliers': (context) => SupplierScreen(),
        '/reports': (context) => ReportScreen(),
      },
    );
  }
}
