import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leave_management_app/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leave_management_app/taskmodule/nextpage.dart';

class Timesheet extends StatefulWidget {
  @override
  State<Timesheet> createState() => _TimesheetState();
}

class _TimesheetState extends State<Timesheet> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService apiService = ApiService();

  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  List<Map<String, dynamic>>? _timesheetData;
  int? _userId;
  bool _isLoading = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
  }

  Future<void> _navigateToNextPage(Map<String, dynamic> dayTask) async {
    try {
      List<Map<String, dynamic>> allTasks = await apiService.getAllTasks();

      // Parse the date from the task list
      DateTime selectedDate = DateFormat('dd-MM-yyyy').parse(dayTask['day']);

      // Filter tasks for the selected date
      List<Map<String, dynamic>> tasksForDate = allTasks.where((task) {
        DateTime taskDate = DateTime.parse(task['task_date']);
        return taskDate.year == selectedDate.year &&
            taskDate.month == selectedDate.month &&
            taskDate.day == selectedDate.day;
      }).toList();

      if (tasksForDate.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NextPage(
              date: dayTask['day'],
              userId: _userId.toString(),
              tasks: tasksForDate,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No tasks found for this date')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching task details: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _toDate = picked;
          _toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _submitTimesheet() async {
    if (_fromDate != null && _toDate != null && _userId != null) {
      try {
        final result = await apiService.tasksubmit(
          _fromDateController.text,
          _toDateController.text,
          _userId.toString(),
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Timesheet successfully submitted!')),
          );

          setState(() {
            _isSubmitted = true; // Mark as submitted
            _timesheetData = []; // Clear the timesheet data
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit timesheet.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting timesheet: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both dates and ensure user ID is loaded.')),
      );
    }
  }

  Future<void> _getTimesheet() async {
    if (_fromDate != null && _toDate != null && _userId != null) {
      setState(() {
        _isLoading = true;
        _isSubmitted = false; // Reset the submission state
      });
      try {
        final data = await apiService.getAllTaskById(
          _userId.toString(),
          _fromDateController.text,
          _toDateController.text,
        );
        setState(() {
          _timesheetData = List<Map<String, dynamic>>.from(data['tasks']);
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both dates.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('User Timesheet'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.filter_list_alt),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF013457)),
              child: Text(
                'Filter Task',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.date_range),
              title: TextField(
                controller: _fromDateController,
                decoration: InputDecoration(labelText: 'From Date'),
                onTap: () => _selectDate(context, true),
              ),
            ),
            ListTile(
              leading: Icon(Icons.date_range),
              title: TextField(
                controller: _toDateController,
                decoration: InputDecoration(labelText: 'To Date'),
                onTap: () => _selectDate(context, false),
              ),
            ),
            ListTile(
              title: ElevatedButton(
                onPressed: () {
                  // Call the _getTimesheet function
                  _getTimesheet();

                  // Close the drawer when the button is clicked
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF013457),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                ),
                child: Text('Get Timesheet'),
              ),
            ),

          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _timesheetData != null && _timesheetData!.isNotEmpty
          ? SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: List.generate(_timesheetData!.length, (index) {
              final task = _timesheetData![index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title:   TextButton(
                    onPressed: () => _navigateToNextPage(task),
                    child: Text(
                      'Date: ${task['day']}',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('S.No: ${index + 1}'),
                      Text('Total Hours: ${task['total_hours_per_day']}'),
                      Text('Status: ${task['approved_status']}'),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No timesheet data available.'),
            SizedBox(height: 10),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 200, // Adjust width as needed
        child: ElevatedButton(
          onPressed: _isSubmitted ? null : _submitTimesheet,
          style: ElevatedButton.styleFrom(
             // Colors.grey : Color(0xFF013457), // Button color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            padding: EdgeInsets.symmetric(vertical: 15), // Height of the button
          ),
          child: Text(
            _isSubmitted ? 'Submitted' : 'Submit Timesheet',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

}







