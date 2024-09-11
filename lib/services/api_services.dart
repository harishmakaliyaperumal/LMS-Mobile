import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://lms-api.annularprojects.com:3001';

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final String loginUrl = 'https://lms-api.annularprojects.com:3001/api/auth/login';
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    // print("check");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    else {
      throw Exception('Failed to login: ${response.body}');
    }
  }



  // LEAVE MANAGEMENT
  Future<Map<String, dynamic>> fetchLeaveBalance(String userId) async {
    final String leaveBalanceUrl = 'https://lms-api.annularprojects.com:3001/api/leave/leave-balance/$userId';
    final response = await http.get(
      Uri.parse(leaveBalanceUrl),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      // print('leave balance :${response.body}');
      return jsonDecode(response.body);
    }
    else {
      throw 'Leave not Allocated Please contact Admin.';

    }
  }

  Future<Map<String, dynamic>?> addleave(String userId,
      String fromDate,
      String toDate,
      String totalDays,
      String session,
      String leaveType,
      String reason

      // String reason,
      ) async {

    var data = {
      "user_id": userId,
      "from_date": fromDate,
      "to_date": toDate,
      "total_days": totalDays,
      "session": session,
      "reason": reason,
      "leave_type": leaveType,
    };
    final String leaveApplyUrl = 'https://lms-api.annularprojects.com:3001/api/leave/request-leave';


    // print('create leavae: ,${data}');
    final response = await http.post(
      Uri.parse(leaveApplyUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      // print("Response: ${response.body}");
      var leaveResponse = {
        "success": true,
        "message": "Leave applied successfully",
        "data": jsonDecode(response.body)
      };


      // Fetch leave balance after successful leave application
      try {
        var leaveBalance = await fetchLeaveBalance(userId);
        leaveResponse['leave_balance'] = leaveBalance;
      } catch (e) {
        // print('Failed to fetch leave balance: $e');
      }

      return leaveResponse;
    } else {
      throw Exception('Failed to apply leave: ${response.body}');
    }
  }


  Future<Map<String, dynamic>> getuserdetailsbyid(String userId) async {
        final String getuserdetailsbyidUrl = 'https://lms-api.annularprojects.com:3001/api/auth/user/$userId';
        final response = await http.get(
          Uri.parse(getuserdetailsbyidUrl),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Failed to fetch user data: ${response.body}');
        }
  }


  Future<List<dynamic>> fetchOptionalLeaveData(String userId) async {
    final String fetchOptionalLeaveDataUrl = 'https://lms-api.annularprojects.com:3001/api/holiday/optional_holiday';
    final response = await http.get(
      Uri.parse(fetchOptionalLeaveDataUrl),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // This should return a List<dynamic>
    } else {
      throw Exception('Failed to fetch leave data: ${response.body}');
    }
  }





  Future<Map<String, dynamic>> leavehistroy(String userId) async {
    final String leavehistroyUrl =
        'https://lms-api.annularprojects.com:3001/api/leave/leave-history/$userId';
    final response = await http.get(
      Uri.parse(leavehistroyUrl),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch leave data: ${response.body}');
    }
  }


//   TIMESHEETS TASK MODEL API FUNCTIONS


  Future<Map<String, dynamic>?> createtask(String taskname,
      String tasktime,
      int userId, // Change to int
      String taskdate,) async {
    var data = {
      "task_name": taskname,
      "task_time": tasktime,
      "user_id": userId, // No need for conversion
      "task_date": taskdate,
    };
    print("Data to be sent: $data");

    const String createtaskUrl = 'https://lms-api.annularprojects.com:3001/api/task/create_task';

    try {
      final response = await http.post(
        Uri.parse(createtaskUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      // Print the HTTP response details
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        // Successfully created the task, return the parsed response
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print("Parsed Response Data: $responseData");
        return responseData;
      } else {
        // Handle errors based on the status code
        print("Error Response Body: ${response.body}");
        throw Exception('Failed to add task: ${response.body}');
      }
    } catch (e) {
      // Print error details
      print("Error occurred: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> getAllTaskById(String userId, String fromDate,
      String toDate) async {
    final String getTaskByIdUrl = 'https://lms-api.annularprojects.com:3001/api/task/weekly/$userId?fromDate=$fromDate&toDate=$toDate';

    print("Fetching tasks from URL: $getTaskByIdUrl");

    final response = await http.get(
      Uri.parse(getTaskByIdUrl),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      print("Failed to fetch task data: ${response.body}");
      throw Exception('Failed to fetch task data: ${response.body}');
    }
  }


  Future<Map<String, dynamic>?> tasksubmit(String fromDate,
      String toDate,
      String userId,) async {
    var data = {
      "fromDate": fromDate,
      "toDate": toDate,
      "userId": userId
    };
    print("Data to be sent: $data");
    final String loginUrl = 'https://lms-api.annularprojects.com:3001/api/task/create_weekly_status';
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    print("checktest");
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }


  Future<List<Map<String, dynamic>>> fetchTaskHistory(String userId) async {
    final String url = 'https://lms-api.annularprojects.com:3001/api/task/get_weekly_status_by_id/$userId';
    final response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(responseData['weeklyStatuses']);
    } else {
      throw Exception('Failed to fetch task history data: ${response.body}');
    }
  }






  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final String url =
        'https://lms-api.annularprojects.com:3001/api/task/get_all_tasks';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        List<Map<String, dynamic>> tasks =
        jsonResponse.cast<Map<String, dynamic>>();
        return tasks;
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      throw Exception('Error fetching tasks: $e');
    }
  }




  Future<void> updateTask(String taskId, String taskName, String taskTime, String taskDate, int userId,String status) async {
    final String updateTaskUrl = 'https://lms-api.annularprojects.com:3001/api/task/update_task_by_id/$taskId';

    final response = await http.put(
      Uri.parse(updateTaskUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "task_name": taskName,
        "task_time": taskTime,
        "task_date": taskDate,
        "user_id": userId,
        "approved_status": status,
      }),
    );

    if (response.statusCode == 200) {
      print("Task updated successfully");
    } else {
      print("Failed to update task: ${response.body}");
      throw Exception('Failed to update task');
    }
  }



  Future<void> deleteTask(String taskId) async {
    final String deleteTaskUrl = 'https://lms-api.annularprojects.com:3001/api/task/delete_task/$taskId';

    try {
      final response = await http.delete(
        Uri.parse(deleteTaskUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 204) {
        print("Task deleted successfully");
      } else {
        print("Failed to delete task: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to delete task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error deleting task: $e");
      throw Exception('Error deleting task: $e');
    }
  }
  Future<List<dynamic>> getAllLeaveRequests(String userId) async {
    final String getallleaverequestUrl =
        'https://lms-api.annularprojects.com:3001/api/leave/get-all-leave-request';
    final response = await http.get(
      Uri.parse(getallleaverequestUrl),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user data: ${response.body}');
    }
  }




}
