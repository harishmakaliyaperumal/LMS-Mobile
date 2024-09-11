import 'package:flutter/material.dart';

class Taskreport extends StatelessWidget {
  final Map<String, dynamic> taskData;

  Taskreport({required this.taskData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> tasks = taskData['tasks'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${task['day']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Total Hours: ${task['total_hours_per_day']}', style: TextStyle(fontSize: 16)),
                          Text('Status: ${task['approved_status']}', style: TextStyle(fontSize: 16)),
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
