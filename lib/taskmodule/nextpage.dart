import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leave_management_app/services/api_services.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class NextPage extends StatefulWidget {
  final String date;
  final String userId;
  final List<Map<String, dynamic>> tasks;

  const NextPage({
    Key? key,
    required this.date,
    required this.userId,
    required this.tasks,
  }) : super(key: key);

  @override
  _NextPageState createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  late List<Map<String, dynamic>> _tasks;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks);
  }


  String _formatTime(String taskTime) {
    try {
      final time = DateFormat("HH:mm:ss").parse(taskTime); // Adjust parsing as needed
      return DateFormat("HH:mm").format(time); // Format to HH:MM
    } catch (e) {
      print("Error formatting time: $e");
      return taskTime; // Return the original if parsing fails
    }
  }


  void _editTask(int index) {
    final timeRegex = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$'); // Regex to match valid time format HH:MM

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String taskTime = _tasks[index]['task_time'];
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                initialValue: _tasks[index]['task_name'],
                decoration: InputDecoration(labelText: 'Task Name'),
                onChanged: (value) {
                  _tasks[index]['task_name'] = value;
                },
              ),
              TextFormField(
                initialValue: taskTime,
                decoration: InputDecoration(labelText: 'Task Time (HH:MM)'),
                onChanged: (value) {
                  taskTime = value;
                },
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  // Ensure the input is formatted as HH:MM
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                  LengthLimitingTextInputFormatter(5),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                if (!timeRegex.hasMatch(taskTime)) {
                  // Show error if the time format is invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid time format. Please enter time as HH:MM.')),
                  );
                  return;
                }

                try {
                  String taskId = _tasks[index]['task_id'].toString();
                  String taskName = _tasks[index]['task_name'];
                  String taskDate = _tasks[index]['task_date'];
                  int userId = _tasks[index]['user_id'];

                  // Change the status to "pending"
                  String updatedStatus = "pending";

                  await ApiService().updateTask(
                    taskId,
                    taskName,
                    taskTime,
                    taskDate,
                    userId,
                    updatedStatus,
                  );

                  setState(() {
                    _tasks[index]['approved_status'] = updatedStatus;
                    _tasks[index]['task_time'] = taskTime;
                  });

                  Navigator.of(context).pop(); // Close the dialog after saving
                } catch (e) {
                  print("Error updating task: $e");
                  // Handle error, maybe show a Snackbar or AlertDialog with the error message
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(int index) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                try {
                  String taskId = _tasks[index]['task_id'].toString();

                  // Call the API to delete the task
                  await apiService.deleteTask(taskId);

                  setState(() {
                    // Remove the task from the local list
                    _tasks.removeAt(index);
                  });

                  Navigator.of(context).pop(); // Close the dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Task successfully deleted.')),
                  );

                } catch (e) {
                  print("Error deleting task: $e");
                  // Handle error, maybe show a Snackbar or AlertDialog with the error message
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details for ${widget.date}'),
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          bool isApproved = task['approved_status'] == "approved";

          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title:Text('Task ID: ${task['task_id']}'),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task Name: ${task['task_name']}'),
                  Text('Task Time: ${_formatTime(task['task_time'])}'),
                  Text('Status: ${task['approved_status']}'),
                ],
              ),
              trailing: isApproved
                  ? null // No buttons if the status is approved
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editTask(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTask(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
