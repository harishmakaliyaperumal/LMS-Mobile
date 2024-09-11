import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leave_management_app/common/constants.dart';
import 'package:leave_management_app/leavecategories/addleave.dart';
// import 'package:leave_management_app/leavecategories/applyleave.dart';
import 'package:leave_management_app/leavecategories/leave_history.dart';
import 'package:leave_management_app/auth/loginscreen.dart';
import 'package:leave_management_app/services/api_services.dart';
import 'package:leave_management_app/taskmodule/calendar_screen.dart';
import 'package:leave_management_app/taskmodule/taskhistroy.dart';
import 'package:leave_management_app/taskmodule/timesheet.dart';
import 'package:leave_management_app/userprofile/userdetails.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late Map<String, dynamic> loginResponse;
  late Future<Map<String, dynamic>> leaveDataFuture;
  ApiService apiService = ApiService();


  Future<Map<String, dynamic>> getLeaveData() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');
    if (userId != null) {
      return await apiService.fetchLeaveBalance(userId.toString());
    } else {
      throw Exception('User ID not found');
    }
  }

  @override
  void initState() {
    super.initState();
    loginResponse = Get.arguments;
    leaveDataFuture = getLeaveData();

  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      leaveDataFuture = getLeaveData();
    });
  }

  void refreshLeaveData() {
    setState(() {
      leaveDataFuture = getLeaveData();
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    Get.offAll(LoginScreen());
  }

  // Future<void> _loadGender() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     gender = prefs.getString('user_gender'); // Retrieve the gender
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final empName = loginResponse['emp_name'] ?? 'User';
    final userId = loginResponse['user_id'] ?? 'User';
    final gender = loginResponse['gender'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text('$empName'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'User Email':
                // Handle user email action
                  break;
                case 'Change Password':
                // Handle forgot password action
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'User Email', 'Forgot Password', 'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice.toLowerCase().replaceAll(' ', ''),
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF013457), // Background color
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Image
                  Image.asset(
                    AppConstants.logo,
                    height: 80.0,
                    width: 80.0,
                  ),
                  SizedBox(width: 16.0),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loginResponse['emp_name'] ?? 'User Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18.0 : 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        loginResponse['email'] ?? 'user@example.com',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('User Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Userdetails(
                      userId: userId.toString(),
                    ),
                  ),
                );
              },
            ),
            ExpansionTile(
              leading: Icon(Icons.deblur_outlined),
              title: Text('Leave Management'),
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Apply leave'),
                  onTap: () async {
                    Map<String, dynamic> leaveData = await leaveDataFuture;
                    bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddLeave(
                          leaveData: leaveData,
                          gender: gender,
                          // onLeaveApplied: refreshLeaveData, // Add this callback
                        ),
                      ),
                    );
                    if (result == true) {
                      refreshLeaveData();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history_edu_outlined),
                  title: Text('Leave History'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    int? userId = prefs.getInt('userId');

                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaveHistoryPage(
                            userId: userId.toString(),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User ID not found')),
                      );
                    }
                  },
                ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.task_alt_outlined),
              title: Text('Task Management'),
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.task_outlined),
                  title: Text('Add Task'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    int? userId = prefs.getInt('userId');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CalendarScreen(userId: userId.toString())
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('TimeSheet'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Timesheet()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Task History'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    int? userId = prefs.getInt('userId'); // Retrieve the userId as int

                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskHistory(
                            userId: userId, // Pass userId as int
                            apiService: ApiService(),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User ID not found')),
                      );
                    }
                  },
                )
              ],
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: leaveDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return _getPageContent(_selectedIndex, snapshot.data!);
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Apply Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Leave History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF013457), // Light pink color
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _getPageContent(int index, Map<String, dynamic> leaveData) {
    switch (index) {
      case 0:
        return DashboardHome(leaveData: leaveData,gender: loginResponse['gender'] ?? '',);
      case 1:
        return AddLeave(
          leaveData: leaveData,
          gender: loginResponse['gender'] ?? '',
          // onLeaveApplied: refreshLeaveData, // Add this callback
        );
      case 2:
        return LeaveHistoryPage(userId: loginResponse['user_id'].toString());
      default:
        return DashboardHome(leaveData: leaveData,gender: loginResponse['gender'] ?? '',);
    }
  }
}

class DashboardHome extends StatelessWidget {
  final Map<String, dynamic> leaveData;
  final String gender;


  DashboardHome({required this.leaveData,required this.gender});


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 35.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isSmallScreen ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      // Text(
                      //   'Gender: $gender', // Display the userId
                      //   style: TextStyle(
                      //     fontSize: isSmallScreen ? 16.0 : 18.0,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      Text(
                        'Upcoming Holidays..',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16.0 : 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: isSmallScreen ? 20.0 : 24.0),
                          SizedBox(width: 15.0),
                          Text(
                            '15th August independence day',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16.0 : 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.0),
          Container(
            child: Row(
              children: [
                Text(
                  'Leave Categories',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16.0 : 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14.0,
              mainAxisSpacing: 14.0,
              children: [
                CategoryItem(
                  title: 'Earned Leave',
                  text: leaveData['earned_leave']?.toString() ?? '0',
                  onTap: () {},
                ),
                CategoryItem(
                  title: 'Sick Leave',
                  text: leaveData['sick_leave']?.toString() ?? '0',
                  onTap: () {
                    // Handle Sick Leave action
                  },
                ),
                CategoryItem(
                  title: 'Optional Leave',
                  text: leaveData['optional_leave']?.toString() ?? '0',
                  onTap: () {
                    // Handle Optional Leave action
                  },
                ),
                if (gender == 'F')
                  CategoryItem(
                    title: 'Maternity Leave',
                    text: leaveData['maternity_leave']?.toString() ?? '0',
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String title;
  final String text;
  final VoidCallback onTap;

  CategoryItem({required this.title, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                text,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
