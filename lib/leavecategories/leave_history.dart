import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leave_management_app/services/api_services.dart';

class LeaveHistoryPage extends StatefulWidget {
  final String userId;

  LeaveHistoryPage({required this.userId});

  @override
  _LeaveHistoryPageState createState() => _LeaveHistoryPageState();
}

class _LeaveHistoryPageState extends State<LeaveHistoryPage> {
  Future<Map<String, dynamic>>? leaveHistoryFuture;
  final ApiService apiService = ApiService(); // Create an instance of ApiService

  @override
  void initState() {
    super.initState();
    leaveHistoryFuture = apiService.leavehistroy(widget.userId); // Call from the service
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave History'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: leaveHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['data'].isEmpty) {
            return Center(child: Text('No leave history found.'));
          } else {
            List<dynamic> leaveData = snapshot.data!['data'];

            return ListView.builder(
              itemCount: leaveData.length,
              itemBuilder: (context, index) {
                var leave = leaveData[index];
                Color statusColor;

                switch (leave['status']) {
                  case 'approved':
                    statusColor = Colors.green.shade100; // Light green
                    break;
                  case 'rejected':
                    statusColor = Colors.red.shade100; // Light red
                    break;
                  case 'pending':
                    statusColor = Colors.yellow.shade100; // Light yellow
                    break;
                  default:
                    statusColor = Colors.grey.shade100; // Light grey
                }

                // Parsing and formatting the dates with null safety
                String fromDate = _formatDate(leave['from_date'] ?? '');
                String toDate = _formatDate(leave['to_date'] ?? '');


                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leave Type: ${_getLeaveType(leave['leave_type'])}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'From: $fromDate',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'To: $toDate',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Total Days: ${leave['total_days']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            leave['status']?.toUpperCase() ?? 'UNKNOWN',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Helper function to format date strings for display
  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date); // Changed to 'dd-MM-yyyy' format
    } catch (e) {
      return dateStr; // If parsing fails, return the original string
    }
  }

  // Helper function to get the readable leave type
  String _getLeaveType(String? leaveType) {
    // Map of leave types that might be used by backend
    Map<String, String> leaveTypes = {
      'earned_leave': 'Earned Leave',
      'maternity_leave': 'Maternity Leave',
      'casual_leave': 'Casual Leave',
      'sick_leave': 'Sick Leave',
      'loss_of_pay': 'Loss Of Pay',
      'work_from_home':'Work From Home'
      // Add any other types as required
    };

    // Return the readable type or 'Unknown Type' if not found
    return leaveTypes[leaveType?.toLowerCase()] ?? leaveType ?? 'Unknown Type';
  }
}
