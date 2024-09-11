import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:leave_management_app/common/constants.dart';
import 'package:leave_management_app/controller/auth_controller.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final RxBool _obscureText = true.obs;

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,  // 8% of the screen width
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1), // 10% of the screen height
              Image.asset(
                AppConstants.logo,
                height: screenHeight * 0.2,  // 20% of the screen height
              ),
              SizedBox(height: screenHeight * 0.05), // 5% of the screen height
              const Text(
                'Login to your account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.04), // 4% of the screen height
              TextFormField(
                controller: authController.email,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 18.0,
                    horizontal: 18.0,
                  ),
                  prefixIcon: Icon(
                    Icons.email,
                    color: Colors.black87,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16.0,
                  fontFamily: 'Poppins',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!EmailValidator.validate(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: screenHeight * 0.04), // 4% of the screen height
              Obx(
                    () => TextField(
                  controller: authController.password,
                  obscureText: _obscureText.value,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18.0,
                      horizontal: 18.0,
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Colors.black87,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black87,
                      ),
                      onPressed: () {
                        _obscureText.value = !_obscureText.value;
                      },
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16.0,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04), // 4% of the screen height
              ElevatedButton(
                onPressed: () async {
                  await authController.login();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF013457),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.2,  // 20% of the screen width
                    vertical: screenHeight * 0.02,  // 2% of the screen height
                  ),
                ),
                child: Text('Login'),
              ),
              SizedBox(height: screenHeight * 0.04), // 4% of the screen height
              TextButton(
                onPressed: () {
                  // Navigate to the registration screen
                },
                child: const Text("Forgot your password"),
              ),
              SizedBox(height: screenHeight * 0.1), // 10% of the screen height
            ],
          ),
        ),
      ),
    );
  }
}
