import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leave_management_app/services/api_services.dart';

class AddLeave extends StatefulWidget {
  final Map<String, dynamic> leaveData;
  final String gender;

  const AddLeave({
    Key? key,
    required this.leaveData,
    required this.gender,
  }) : super(key: key);

  @override
  _AddLeaveState createState() => _AddLeaveState();
}

class _AddLeaveState extends State<AddLeave> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fromDate;
  DateTime? _toDate;

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  String? _selectedCategory;
  String? _selectedLeaveDuration;
  Map<String, String> _leaveType = {};
  final Map<String, String> _leaveDurations = {
    'Full Day': 'full_day',
    'FN': 'FN',
    'AN': 'AN',
  };
  bool _isLoading = false;
  String? _selectedHolidayOrTesting;
  List<Map<String, dynamic>> _holidayOptions = [];

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _retrieveGenderAndInitializeLeaveTypes();
  }

  Future<void> _retrieveGenderAndInitializeLeaveTypes() async {
    String gender = widget.gender;
    bool isFemale = gender == 'F';

    setState(() {
      _leaveType = {
        'Earned Leave': widget.leaveData['earned_leave']?.toString() ?? '0',
        'Sick Leave': widget.leaveData['sick_leave']?.toString() ?? '0',
        'Optional Holiday': widget.leaveData['optional_leave']?.toString() ?? '0',
        if (isFemale)
          'Maternity Leave':
          widget.leaveData['maternity_leave']?.toString() ?? '0',
        'Loss Of Pay': widget.leaveData['loss_of_pay']?.toString() ?? '0',
        'Work From Home': widget.leaveData['work_from_home']?.toString() ?? '0',
      };
    });
  }

  Future<void> _fetchAndSetOptionalHolidayOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> response = await _apiService.fetchOptionalLeaveData(widget.leaveData['user_id'].toString());

      setState(() {
        _holidayOptions = response.map((holiday) => {
          'value': holiday['date'], // Use date as value
          'display': '${_formatDate(holiday['date'])} (${holiday['description']})' // Formatted display string
        }).toList();

        _selectedHolidayOrTesting = _holidayOptions.isNotEmpty ? _holidayOptions[0]['display'] : null;
        _fromDateController.text = _holidayOptions.isNotEmpty ? _holidayOptions[0]['value'] : '';
        _toDateController.text = _holidayOptions.isNotEmpty ? _holidayOptions[0]['value'] : '';
      });
    } catch (e) {
      print('Error fetching optional holiday options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching optional holiday options: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function to format the date to "DD-MM-YYYY"
  String _formatDate(String dateString) {
    try {
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(parsedDate); // Change format for display
    } catch (e) {
      print('Date parsing error: $e');
      return dateString;
    }
  }

  Future<void> _applyLeave() async {
    if (_formKey.currentState!.validate()) {
      int earnedLeave = double.tryParse(widget.leaveData['earned_leave']?.toString() ?? '0')?.toInt() ?? 0;
      int sickLeave = double.tryParse(widget.leaveData['sick_leave']?.toString() ?? '0')?.toInt() ?? 0;

      // Check if Loss Of Pay is selected
      if (_selectedCategory == 'Loss Of Pay') {
        if (earnedLeave > 0 || sickLeave > 0) {
          _showLossOfPayPopup('Loss of Pay can only be applied if Sick and Earned leave balances are 0.');
          return;
        }
      }

      DateTime fromDateTime = DateTime.parse(_fromDateController.text);
      DateTime toDateTime = DateTime.parse(_toDateController.text);
      // DateTime currentDate = DateTime.now();

      // Check if FN or AN leave is selected and validate the date
      // if ((_selectedLeaveDuration == 'FN' || _selectedLeaveDuration == 'AN') &&
      //     (fromDateTime.day != currentDate.day ||
      //         fromDateTime.month != currentDate.month ||
      //         fromDateTime.year != currentDate.year)) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Dear user, FN and AN leave can only be applied for the current date.')),
      //   );
      //   return;
      // }

      // Check if the selected dates are weekends
      bool isWeekend(DateTime date) {
        return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      }

      if (isWeekend(fromDateTime) || isWeekend(toDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weekend dates cannot be selected as start or end dates.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _apiService.addleave(
          widget.leaveData['user_id'].toString(),
          _selectedCategory == 'Optional Holiday' ? _fromDateController.text : _fromDateController.text,
          _selectedCategory == 'Optional Holiday' ? _toDateController.text : _toDateController.text,
          _selectedCategory == 'Optional Holiday' ? '1.0' : _calculateTotalDays().toString(),
          _selectedCategory == 'Optional Holiday' ? 'Full Day' : (_selectedLeaveDuration ?? 'Full Day'),
          _selectedCategory?.toLowerCase().replaceAll(' ', '_') ?? 'earned_leave',
          _selectedCategory == 'Optional Holiday' ? 'Optional Holiday' : _reasonController.text,
        );

        // change 1

        if (response != null && response['success'] == true) {
          Map<String, dynamic>? leaveBalance = response['leave_balance'];

          setState(() {
            if (leaveBalance != null) {
              widget.leaveData.addAll(leaveBalance);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Leave applied successfully')),
          );

          Navigator.pop(context, true);
        } else {
          throw Exception(response?['message'] ?? 'Failed to apply leave');
        }
      } catch (e) {
        print('Error applying leave: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying leave: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _showLossOfPayPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cannot Apply Loss of Pay'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime now = DateTime.now();
    final DateTime defaultFirstDate = now.subtract(Duration(days: 30));
    final DateTime defaultLastDate = now.add(Duration(days: 90));

    // Set allowed date ranges based on selected leave type
    final DateTime firstAllowedDate = _selectedCategory == 'Maternity Leave' ? DateTime(2000) : defaultFirstDate;
    final DateTime lastAllowedDate = _selectedCategory == 'Maternity Leave' ? DateTime(2100) : defaultLastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstAllowedDate,
      lastDate: lastAllowedDate,
    );

    if (picked != null) {
      setState(() {
        final displayFormat = DateFormat('yyyy-MM-dd');
        if (isFromDate) {
          _fromDate = picked;
          _fromDateController.text = displayFormat.format(picked);

          // Automatically set the To Date to 180 days later for Maternity Leave, including weekends
          if (_selectedCategory == 'Maternity Leave') {
            _toDate = _fromDate!.add(Duration(days: 180));
            _toDateController.text = displayFormat.format(_toDate!);
          } else if (_selectedLeaveDuration == 'FN' || _selectedLeaveDuration == 'AN') {
            _toDate = _fromDate;
            _toDateController.text = displayFormat.format(_fromDate!);
          }
        } else {
          if (picked.isBefore(_fromDate ?? DateTime.now())) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('To Date should be after From Date.')),
            );
          } else {
            _toDate = picked;
            _toDateController.text = displayFormat.format(picked);
          }
        }
      });
    }
  }


  double _calculateTotalDays() {
    if (_fromDate != null && _toDate != null) {
      int daysDifference = _toDate!.difference(_fromDate!).inDays + 1;

      int weekdays = 0;
      for (int i = 0; i < daysDifference; i++) {
        DateTime currentDate = _fromDate!.add(Duration(days: i));
        if (currentDate.weekday >= DateTime.monday && currentDate.weekday <= DateTime.friday) {
          weekdays++;
        }
      }

      double totalDays = weekdays * (_selectedLeaveDuration == 'Full Day' ? 1.0 : 0.5);
      return totalDays;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Apply Leave',
          style: TextStyle(fontSize: 20), // Adjust font size if needed
        ),
      ),


      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply for Leave',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    _buildDropdownField(
                      labelText: 'Leave Type',
                      hintText: 'Select',
                      value: _selectedCategory,
                      items: _leaveType.keys.toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          if (_selectedCategory == 'Optional Holiday') {
                            _fromDateController.clear();
                            _toDateController.clear();
                            _reasonController.clear();
                          }
                          _triggerApiOrLogicForLeaveType(value);
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    if (_selectedCategory != 'Optional Holiday') // Hide duration dropdown if 'Optional Holiday' is selected
                      _buildDropdownField(
                        labelText: 'Leave Duration',
                        hintText: 'Select',
                        value: _selectedLeaveDuration,
                        items: _leaveDurations.keys.toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLeaveDuration = value;
                          });
                        },
                      ),
                    if (_selectedCategory == 'Optional Holiday') ...[
                      SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedHolidayOrTesting,
                        hint: Text('Select'),
                        items: _holidayOptions.map<DropdownMenuItem<String>>((holiday) {
                          return DropdownMenuItem<String>(
                            value: holiday['display'] as String,  // Ensure this is a String
                            child: Text(holiday['display'] as String),  // Ensure this is a String
                          );
                        }).toList(), // Casting is unnecessary here as we ensured the type is String
                        onChanged: (value) {
                          setState(() {
                            _selectedHolidayOrTesting = value;
                            // Update _fromDateController and _toDateController based on selected holiday
                            var selectedOption = _holidayOptions.firstWhere(
                                  (option) => option['display'] == value,
                              orElse: () => {},
                            );
                            if (selectedOption.isNotEmpty) {
                              _fromDateController.text = selectedOption['value']!;
                              _toDateController.text = selectedOption['value']!;
                            }
                          });
                        },
                      )

                    ],
                    SizedBox(height: 16),
                    if (_selectedCategory != 'Optional Holiday')
                      TextFormField(
                        controller: _fromDateController,
                        decoration: InputDecoration(
                          labelText: 'From Date',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        readOnly: true,
                        validator: (value) => value!.isEmpty ? 'Please select a from date' : null,
                      ),
                    SizedBox(height: 16),
                    if (_selectedCategory != 'Optional Holiday')
                      TextFormField(
                        controller: _toDateController,
                        decoration: InputDecoration(
                          labelText: 'To Date',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context, false),
                          ),
                        ),
                        readOnly: true,
                        validator: (value) => value!.isEmpty ? 'Please select a to date' : null,
                      ),
                    SizedBox(height: 16),
                    if (_selectedCategory != 'Optional Holiday')
                      TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please provide a reason' : null,
                      ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _applyLeave,
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Text('Submit Leave Application'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String hintText,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hintText),
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
    );
  }

  void _triggerApiOrLogicForLeaveType(String? leaveType) {
    if (leaveType == 'Optional Holiday') {
      _fetchAndSetOptionalHolidayOptions();
    }
  }
}
