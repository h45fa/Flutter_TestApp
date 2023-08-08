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

class UserController extends GetxController {
  var users = <dynamic>[].obs;
  var currentPage = 2.obs; // Initial page number

  Future<void> fetchUsers({int? page}) async {
    if (page != null) currentPage.value = page;

    final response =
        await http.get(Uri.parse('https://reqres.in/api/users?page=${currentPage.value}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      users.assignAll(data['data']);

      saveUserDataToLocal(users);
    } else {
      users.assignAll(await loadUserDataFromLocal());
    }
  }

  void saveUserDataToLocal(List<dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user_data', json.encode(userData));
  }

  Future<List<dynamic>> loadUserDataFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userDataJson = prefs.getString('user_data') ?? '[]';
    return json.decode(userDataJson);
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
  final dynamic user;

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
            backgroundImage: NetworkImage(user['avatar']),
            radius: 40.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            '${user['first_name']} ${user['last_name']}',
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          Text(
            user['email'],
            style: const TextStyle(fontSize: 14.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class UserDetailsScreen extends StatelessWidget {
  final dynamic user;

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
              backgroundImage: NetworkImage(user['avatar']),
              radius: 64.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              '${user['first_name']} ${user['last_name']}',
              style:
                  const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            Text('ID: ${user['id']}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Text(user['email'], style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
}
