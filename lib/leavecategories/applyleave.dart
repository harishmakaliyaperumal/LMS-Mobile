import 'package:flutter/material.dart';
import 'package:leave_management_app/leavecategories/addleave.dart';
import 'package:table_calendar/table_calendar.dart';

class Applyleave extends StatefulWidget {
  final Map<String, dynamic> leaveData;
  final VoidCallback onLeaveApplied;
  final String gender;

  const Applyleave({super.key, required this.leaveData,required this.onLeaveApplied,required this.gender,});

  @override
  State<Applyleave> createState() => _ApplyleaveState();
}

class _ApplyleaveState extends State<Applyleave> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {

    // print('Gender: ${widget.gender}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Add the TextButton instead of FloatingActionButton
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return AddLeave(
                      leaveData: widget.leaveData,
                      gender: widget.gender,
                      // 'user_id': widget.leaveData['userId'],

                    );
                  },
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue, // Button background color
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), // Button padding
              ),
              child: const Text(
                'Apply Leave',
                style: TextStyle(
                  color: Colors.white, // Text color
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
