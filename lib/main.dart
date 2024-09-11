import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leave_management_app/auth/loginscreen.dart';
import 'package:leave_management_app/dashboardscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if a token exists
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  // Validate the token
  if (token == null) {
    runApp(MyApp(initialRoute: '/'));
  } else {
    // Optionally, you could validate the token further here
    runApp(MyApp(initialRoute: '/dashboard'));
  }
}


class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leave Management App',
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/', page: () => LoginScreen()),
        GetPage(name: '/dashboard', page: () => DashboardScreen()),
      ],
    );
  }
}

