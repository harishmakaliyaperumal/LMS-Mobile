import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leave_management_app/services/api_services.dart';
// import 'package:shared_preferences/shared_preferences.dart';

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
    'AN': 'AN',
    'FN': 'FN',
  };
  bool _isLoading = false;
  String? _selectedHolidayOrTesting;
  List<String> _holidayOptions = [];

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
        'Optional Leave': widget.leaveData['optional_leave']?.toString() ?? '0',
        if (isFemale)
          'Maternity Leave':
              widget.leaveData['maternity_leave']?.toString() ?? '0',
        'Loss Of Pay': widget.leaveData['loss_of_pay']?.toString() ?? '0',
        'Work From Home': widget.leaveData['work_from_home']?.toString() ?? '0',
      };
    });
  }

  Future<void> _applyLeave() async {
    if (_formKey.currentState!.validate()) {
      int earnedLeave =
          double.tryParse(widget.leaveData['earned_leave']?.toString() ?? '0')
                  ?.toInt() ??
              0;
      int sickLeave =
          double.tryParse(widget.leaveData['sick_leave']?.toString() ?? '0')
                  ?.toInt() ??
              0;

      // Check if the selected category is 'Loss Of Pay'
      if (_selectedCategory == 'Loss Of Pay') {
        // If either Earned Leave or Sick Leave has a balance greater than 0
        if (earnedLeave > 0 || sickLeave > 0) {
          _showLossOfPayPopup(
              'Loss of Pay can only be applied if Sick and Earned leave balances are 0.');
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = ApiService();
        print('Applying leave with total days: ${_calculateTotalDays()}');

        final response = await apiService.addleave(
          widget.leaveData['user_id'].toString(),
          _fromDateController.text,
          _toDateController.text,
          _calculateTotalDays().toString(),
          _selectedLeaveDuration ?? 'Full Day',
          _selectedCategory?.toLowerCase().replaceAll(' ', '_') ??
              'earned_leave',
          _reasonController.text,
        );

        if (response != null && response['success'] == true) {
          Map<String, dynamic>? leaveBalance = response['leave_balance'];

          setState(() {
            if (leaveBalance != null) {
              widget.leaveData.addAll(leaveBalance);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Leave applied successfully')),
          );

          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to apply leave.')),
          );
        }
      } catch (e) {
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

  // bool _isWeekend(DateTime date) {
  //   return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  // }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final now = DateTime.now();
    final firstAllowedDate = now.subtract(Duration(days: 30));
    final lastAllowedDate = now.add(Duration(days: 90));

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

          if (_selectedLeaveDuration == 'FN' ||
              _selectedLeaveDuration == 'AN') {
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

  // bool _validateLeaveDates() {
  //   if (_fromDate != null && _toDate != null) {
  //     int daysDifference = _toDate!.difference(_fromDate!).inDays + 1;
  //
  //     for (int i = 0; i < daysDifference; i++) {
  //       DateTime currentDate = _fromDate!.add(Duration(days: i));
  //       if (_isWeekend(currentDate)) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //               content:
  //                   Text('Leave application for weekends is not allowed.')),
  //         );
  //         return false;
  //       }
  //     }
  //   }
  //   return true;
  // }

  double _calculateTotalDays() {
    if (_fromDate != null && _toDate != null) {
      int daysDifference = _toDate!.difference(_fromDate!).inDays + 1;

      int weekdays = 0;
      for (int i = 0; i < daysDifference; i++) {
        DateTime currentDate = _fromDate!.add(Duration(days: i));
        if (currentDate.weekday >= DateTime.monday &&
            currentDate.weekday <= DateTime.friday) {
          weekdays++;
        }
      }

      double totalDays =
          weekdays * (_selectedLeaveDuration == 'Full Day' ? 1.0 : 0.5);
      return totalDays;
    }
    return 0;
  }

  void _fetchAndSetOptionalLeaveOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Expect a list of holidays
      final List<dynamic> response = await _apiService
          .fetchOptionalLeaveData(widget.leaveData['user_id'].toString());
      // print('API response: $response'); // Debug print to check response

      setState(() {
        _holidayOptions = response
            .map((holiday) => '${holiday['date']} (${holiday['description']})')
            .toList();
      });
      // Optionally, set the first option as selected
      _selectedHolidayOrTesting =
          _holidayOptions.isNotEmpty ? _holidayOptions[0] : null;
    } catch (e) {
      // print('Error fetching optional leave options: $e'); // Debug print for error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching optional leave options: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _triggerApiOrLogicForLeaveType(String? selectedLeaveType) {
    if (selectedLeaveType != null) {
      print('Selected Leave Type: $selectedLeaveType'); // Debug print
      if (selectedLeaveType == 'Optional Leave') {
        print('Fetching optional leave options...'); // Debug print
        // Fetch optional leave data if 'Optional Leave' is selected
        _fetchAndSetOptionalLeaveOptions();
      } else {
        print('No action needed for this leave type.'); // Debug print
      }
    } else {
      print('Selected Leave Type is null.'); // Debug print
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply Leave'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply for Leave',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Show the leave type dropdown
              _buildDropdownField(
                labelText: 'Leave Type',
                hintText: 'Select Leave Type',
                value: _selectedCategory,
                items: [],
                // Pass empty list for itemMap scenario
                itemMap: _leaveType,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    // Hide other fields if 'Optional Leave' is selected
                    if (_selectedCategory == 'Optional Leave') {
                      _fromDateController.clear();
                      _toDateController.clear();
                      _reasonController.clear();
                    }
                    _triggerApiOrLogicForLeaveType(value);
                  });
                },
              ),
              if (_selectedCategory != 'Optional Leave') ...[
                SizedBox(height: screenHeight * 0.02),
                _buildDropdownField(
                  labelText: 'Leave Duration',
                  hintText: 'Select Leave Duration',
                  value: _selectedLeaveDuration,
                  items: [],
                  // Pass empty list for itemMap scenario
                  itemMap: _leaveDurations,
                  onChanged: (value) {
                    setState(() {
                      _selectedLeaveDuration = value;
                    });
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                _buildCurvedTextField(
                  controller: _fromDateController,
                  labelText: 'From Date',
                  hintText: 'Select From Date',
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context, true),
                ),
                SizedBox(height: screenHeight * 0.02),
                _buildCurvedTextField(
                  controller: _toDateController,
                  labelText: 'To Date',
                  hintText: 'Select To Date',
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(context, false),
                ),
              ],
              if (_selectedCategory == 'Optional Leave') ...[
                SizedBox(height: screenHeight * 0.02),
                _buildDropdownField(
                  labelText: 'Select Option',
                  hintText: 'Choose Holiday or Testing Option',
                  value: _selectedHolidayOrTesting,
                  items: _holidayOptions,
                  // Pass the holiday options list here
                  itemMap: {},
                  // Pass empty map for list scenario
                  onChanged: (value) {
                    setState(() {
                      _selectedHolidayOrTesting = value;
                    });
                  },
                ),
              ],
              SizedBox(height: screenHeight * 0.02),
              if (_selectedCategory != 'Optional Leave') ...[
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Reason for Leave',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Reason is required';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: screenHeight * 0.04),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _applyLeave,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Apply Leave'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      _fromDateController.clear();
                      _toDateController.clear();
                      _reasonController.clear();

                      setState(() {
                        _selectedCategory = null;
                        _selectedLeaveDuration = null;
                        _fromDate = null;
                        _toDate = null;
                        _selectedHolidayOrTesting = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String hintText,
    required String? value,
    required List<String> items, // For options like holidays
    required Map<String, String> itemMap, // For options like leave types
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hintText),
          onChanged: onChanged,
          items: itemMap.isNotEmpty
              ? itemMap.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 360
                              ? 14
                              : 16),
                    ),
                  );
                }).toList()
              : items.isNotEmpty
                  ? items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 360
                                  ? 14
                                  : 16),
                        ),
                      );
                    }).toList()
                  : [
                      DropdownMenuItem(
                          value: null, child: Text('No options available'))
                    ],
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurvedTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
