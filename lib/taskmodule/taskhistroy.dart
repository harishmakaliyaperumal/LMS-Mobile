import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'taskreport.dart';

import 'package:leave_management_app/services/api_services.dart';


class TaskHistory extends StatefulWidget {
  final int userId;
  final ApiService apiService;


  const TaskHistory({super.key, required this.userId, required this.apiService});

  @override
  _TaskHistoryState createState() => _TaskHistoryState();
}

class _TaskHistoryState extends State<TaskHistory> {
  late Future<List<Map<String, dynamic>>> taskHistoryData;

  @override
  void initState() {
    super.initState();
    taskHistoryData = widget.apiService.fetchTaskHistory(widget.userId.toString());
  }

  // Helper method to format dates
  String formatDate(String dateString) {
    final DateTime dateTime = DateTime.parse(dateString);
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task History'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: taskHistoryData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final data = snapshot.data!;

              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final task = data[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From Date: ${formatDate(task['from_date'])}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'To Date: ${formatDate(task['to_date'])}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  // Fetch detailed task report for the selected date range
                                  String fromDate = task['from_date'];
                                  String toDate = task['to_date'];
                                  String userId = widget.userId.toString();

                                  // Fetch the detailed task data using the API service
                                  Map<String, dynamic> detailedTaskData = await widget.apiService.getAllTaskById(userId, fromDate, toDate);

                                  // Navigate to Taskreport and pass the selected task data
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Taskreport(taskData: detailedTaskData),
                                    ),
                                  );
                                },
                                child: Text('View Report'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text('No data available'));
            }
          },
        ),
      ),
    );
  }
}

