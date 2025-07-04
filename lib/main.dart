import 'package:flutter/material.dart';
import 'package:jwelstorebill_webapp/screens/GoldBillScreen.dart';
import 'package:jwelstorebill_webapp/screens/LoginScreen.dart';
import 'package:jwelstorebill_webapp/screens/ProductManagementScreen.dart';
import 'package:jwelstorebill_webapp/screens/SilverBillScreen.dart';
import 'package:jwelstorebill_webapp/screens/StaffsDetailsScreen.dart';
import 'package:jwelstorebill_webapp/screens/InvoiceHistoryScreen.dart';
import 'package:jwelstorebill_webapp/screens/CustomerDetailsScreen.dart';
import 'screens/HomeScreen.dart';
import 'screens/AdminScreen.dart';
import 'screens/CashierScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // auto-generated file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jewellery Billing',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminScreen(),
        '/cashier': (context) => const CashierScreen(),
        '/products': (context) => const ProductManagementScreen(),
        '/GoldbillGenerate': (context) =>  GoldBillScreen(),
        '/SilverbillGenerate': (context) =>  SilverBillScreen(),
        '/invoiceHistory': (context) =>  InvoiceHistoryScreen(),
        '/staffDetails': (context) => const StaffDetailsScreen(),
        '/customersDetails': (context) => const CustomerDetailsScreen(),
      },
    );
  }
}
