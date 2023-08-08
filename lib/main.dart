import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const UserInfoApp());

class UserInfoApp extends StatelessWidget {
  const UserInfoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'User Info App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserListScreen(),
    );
  }
}

class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String avatar;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      avatar: json['avatar'],
    );
  }
}

class UserController extends GetxController {
  var users = <User>[].obs;
  var currentPage = 2.obs;

  Future<void> fetchUsers({int? page}) async {
    if (page != null) currentPage.value = page;

    final response =
        await http.get(Uri.parse('https://reqres.in/api/users?page=${currentPage.value}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final usersList = List<Map<String, dynamic>>.from(data['data']);
      users.assignAll(usersList.map((userData) => User.fromJson(userData)));

      saveUserDataToLocal(users);
    } else {
      users.assignAll(await loadUserDataFromLocal());
    }
  }

  void saveUserDataToLocal(List<User> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user_data', json.encode(userData));
  }

  Future<List<User>> loadUserDataFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userDataJson = prefs.getString('user_data') ?? '[]';
    final usersList = List<Map<String, dynamic>>.from(json.decode(userDataJson));
    return usersList.map((userData) => User.fromJson(userData)).toList();
  }
}

class UserListScreen extends StatelessWidget {
  final UserController userController = Get.put(UserController());

  UserListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    userController.fetchUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: userController.users.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      Get.to(
                          () => UserDetailsScreen(user: userController.users[index]));
                    },
                    child: UserCard(user: userController.users[index]),
                  );
                },
              );
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  userController.fetchUsers(page: userController.currentPage.value - 1);
                },
                child: const Text('Previous Page'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  userController.fetchUsers(page: userController.currentPage.value + 1);
                },
                child: const Text('Next Page'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final User user;

  const UserCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(user.avatar),
            radius: 40.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            '${user.firstName} ${user.lastName}',
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          Text(
            user.email,
            style: const TextStyle(fontSize: 14.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class UserDetailsScreen extends StatelessWidget {
  final User user;

  const UserDetailsScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.avatar),
              radius: 64.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              '${user.firstName} ${user.lastName}',
              style:
                  const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            Text('ID: ${user.id}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Text(user.email, style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
}
