import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:leave_management_app/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.userId});

  final String userId;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Remove any character that isn't a digit
    newText = newText.replaceAll(RegExp(r'[^0-9]'), '');

    // Ensure colon is added at the correct position
    if (newText.length >= 3) {
      newText = '${newText.substring(0, 2)}:${newText.substring(2)}';
    } else if (newText.length > 2) {
      newText = newText.substring(0, 2) + ':' + newText.substring(2);
    }

    // Limit input to 5 characters (HH:MM)
    if (newText.length > 5) {
      newText = newText.substring(0, 5);
    }

    // Automatically adjust invalid hours or minutes
    if (newText.length == 5) {
      final hours = int.tryParse(newText.substring(0, 2));
      final minutes = int.tryParse(newText.substring(3, 5));

      // Adjust hours if greater than 23
      if (hours != null && hours > 23) {
        newText = '23:${newText.substring(3, 5)}';
      }

      // Adjust minutes if greater than 59
      if (minutes != null && minutes > 59) {
        newText = '${newText.substring(0, 2)}:59';
      }
    }

    // Maintain cursor position within the valid text range
    int cursorPosition = newText.length;
    if (cursorPosition > newText.length) {
      cursorPosition = newText.length;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}


class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final ApiService _apiService = ApiService();
  DateTime? _dateOfJoining;
  List<DateTime> _filteredDates = [];
  Map<DateTime, List<String>> _taskStatuses = {};


  @override
  void initState() {
    super.initState();
    _fetchDateOfJoining();
    _getAllLeaveRequests();
    _getAllTasks();
  }

  Future<void> _fetchDateOfJoining() async {
    final prefs = await SharedPreferences.getInstance();
    String? dateOfJoiningStr = prefs.getString('date_of_joining');
    if (dateOfJoiningStr != null) {
      setState(() {
        _dateOfJoining = DateTime.parse(dateOfJoiningStr).toLocal();
      });
    }
  }

  bool _isDateInFilteredDates(DateTime date) {
    return _filteredDates.any((filteredDate) => isSameDay(filteredDate, date));
  }

  Future<void> _getAllLeaveRequests() async {
    try {
      final List<dynamic> leaveRequests =
      await _apiService.getAllLeaveRequests(widget.userId);

      final List<Map<String, dynamic>> formattedRequests = leaveRequests
          .where((request) => request is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();

      final filteredRequests = formattedRequests.where((request) {
        return request['user_id'].toString() == widget.userId &&
            (request['status'] == 'pending' || request['status'] == 'approved');
      }).toList();

      _filteredDates.clear();
      if (filteredRequests.isNotEmpty) {
        for (var request in filteredRequests) {
          DateTime fromDate = DateTime.parse(request['from_date']);
          DateTime toDate = DateTime.parse(request['to_date']);

          DateTime currentDate = fromDate;
          while (currentDate.isBefore(toDate) ||
              currentDate.isAtSameMomentAs(toDate)) {
            _filteredDates.add(currentDate);
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No pending or approved leave requests found.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching leave requests: $e'),
      ));
    }
  }

  Future<void> _getAllTasks() async {
    try {
      final tasks = await _apiService.getAllTasks();
      // Filter tasks by userId
      final filteredTasks =
      tasks.where((task) => task['user_id'].toString() == widget.userId);
      _taskStatuses.clear();

      // Populate task statuses based on approval status
      for (var task in filteredTasks) {
        DateTime taskDate = DateTime.parse(task['task_date']);
        String status = task['approved_status'];

        // Group statuses by task date
        if (_taskStatuses.containsKey(taskDate)) {
          _taskStatuses[taskDate]!.add(status);
        } else {
          _taskStatuses[taskDate] = [status];
        }
      }
      // Print filtered tasks to console
      print('Filtered Tasks: $filteredTasks');
      setState(() {});
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }




  void _showAddTaskDialog(DateTime selectedDay) {
    if (_isDateInFilteredDates(selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave already applied on this day.'),
        ),
      );
      return;
    }

    TextEditingController taskController = TextEditingController();
    TextEditingController timeController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please fill out the task name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Task Time (HH:MM)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    TimeInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter task time';
                    }
                    // Validation for HH:MM format
                    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
                    if (!regex.hasMatch(value)) {
                      return 'Enter a valid time in HH:MM format';
                    }
                    return null;
                  },
                ),



              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String taskName = taskController.text.trim();
                  String taskTime = timeController.text.trim();
                  String taskDate =
                  DateFormat('yyyy-MM-dd').format(selectedDay);

                  try {
                    final response = await _apiService.createtask(
                      taskName,
                      taskTime,
                      int.parse(widget.userId),
                      taskDate,
                    );
                    if (response != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task added successfully!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Failed to add task. Null response from server.'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to add task: $e'),
                    ));
                  }

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final currentDate = DateTime.now();
    final thirtyDaysBefore = currentDate.subtract(const Duration(days: 30));
    final thirtyDaysAfter = currentDate.add(const Duration(days: 30));

    if (_dateOfJoining != null) {
      if (selectedDay.isBefore(_dateOfJoining!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Dear user, your joining date is less than the selected date, so please choose a valid date.'),
        ));
        return;
      }
    }

    if (selectedDay.isBefore(thirtyDaysBefore) ||
        selectedDay.isAfter(thirtyDaysAfter)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selected date is out of the 30-day range.'),
      ));
    } else {
      _showAddTaskDialog(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Add '),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
        TableCalendar(
          firstDay: DateTime(1990),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _onDaySelected,
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (date) {
            // Return a list of statuses for the given date
            return _taskStatuses[date] ?? [];
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 1,
            markersAlignment: Alignment.bottomCenter,
            markerSize: 10,
            // markerDecoration: BoxDecoration(
            //   shape: BoxShape.circle,
            //   color: Colors.transparent, // Default color for markers
            // ),
            todayDecoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(Icons.chevron_left),
            rightChevronIcon: Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}
