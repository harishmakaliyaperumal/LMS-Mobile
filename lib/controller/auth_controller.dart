import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leave_management_app/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leave_management_app/dashboardscreen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthController extends GetxController {
  var email = TextEditingController();
  var password = TextEditingController();
  ApiService apiService = ApiService();
  var isLoading = false.obs;

  Future<void> login() async {
    try {
      isLoading.value = true;

      // Call the API service login method
      final response = await apiService.login(email.text, password.text);

      if (response != null) {
        await saveLoginResponse(response);
        Get.off(() => DashboardScreen(), arguments: response);
      } else {
        throw Exception('Unknown error occurred');
      }
    } on Exception catch (e) {
      // Show error message using FlutterToast
      showToastMessage(
        e.toString().contains('Invalid credentials')
            ? 'Invalid credentials, please try again'
            : 'An error occurred: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveLoginResponse(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonResponse = jsonEncode(response);
    await prefs.setString('loginResponse', jsonResponse);
    await prefs.setInt('userId', response['user_id']);
  }

  Future<Map<String, dynamic>?> getLoginResponse() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonResponse = prefs.getString('loginResponse');
    if (jsonResponse != null) {
      return jsonDecode(jsonResponse);
    }
    return null;
  }

  // Toast message display function
  void showToastMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
