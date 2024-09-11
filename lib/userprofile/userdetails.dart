import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leave_management_app/services/api_services.dart';

class Userdetails extends StatefulWidget {
  final String userId;

  const Userdetails({super.key, required this.userId});

  @override
  State<Userdetails> createState() => _UserdetailsState();
}

class _UserdetailsState extends State<Userdetails> {
  late Future<Map<String, dynamic>> userDetails;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    userDetails = apiService.getuserdetailsbyid(widget.userId);
  }

  // Store the date of joining in SharedPreferences
  Future<void> _storeDateOfJoining(String dateOfJoining) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_of_joining', dateOfJoining);
  }

  // Retrieve the date of joining from SharedPreferences
  Future<String?> _getDateOfJoining() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('date_of_joining');
  }

  // Function to format date string to dd-MM-yyyy
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Details"),
      ),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: userDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final userData = snapshot.data!;

              // Store the date of joining in SharedPreferences
              _storeDateOfJoining(userData['date_of_joining'] ?? '');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      userData['emp_name'] ?? 'N/A', // Employee name
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData['work_email'] ?? 'N/A', // Work email
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData['contact_number'] ?? 'N/A', // Contact number
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<String?>(
                      future: _getDateOfJoining(),
                      builder: (context, dateSnapshot) {
                        if (dateSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (dateSnapshot.hasError) {
                          return Text('Error: ${dateSnapshot.error}');
                        } else if (dateSnapshot.hasData) {
                          final dateOfJoining = dateSnapshot.data ?? 'N/A';
                          return Text(
                            'Date of Joining: ${_formatDate(dateOfJoining)}',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          );
                        } else {
                          return const Text(
                            'Date of Joining: N/A',

                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Designation: ${userData['designation'] ?? 'N/A'}', // Designation
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Work Location: ${userData['work_location'] ?? 'N/A'}', // Work location
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${userData['role'] ?? 'N/A'}', // Role
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(child: Text('No data found'));
            }
          },
        ),
      ),
    );
  }
}
