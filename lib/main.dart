import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:github/user_info.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const Github());
}

class Github extends StatelessWidget {
  const Github({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Github',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const GitHubUserScreen()
    );
  }
}

class GitHubUserScreen extends StatefulWidget {
  const GitHubUserScreen({Key? key}) : super(key: key);

  @override
  _GitHubUserScreenState createState() => _GitHubUserScreenState();
}

class _GitHubUserScreenState extends State<GitHubUserScreen> {
  late bool _hasMore;
  late int _pageNumber;
  late int _perPage;
  late bool _error;
  late bool _loading;
  final int defaultUsersPerPageCount = 50;
  late List<User> _users;
  final int _nextPageThreshold = 5;
  late int _userId;
  @override
  void initState() {
    super.initState();
    _hasMore = true;
    _pageNumber = 1;
    _perPage = 50;
    _error = false;
    _loading = true;
    _users = [];
    _userId = 1;
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Github")),
      body: getBody(),
    );
  }

  Widget getBody() {
    if (_users.isEmpty) {
      if (_loading) {
        return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ));
      } else if (_error) {
        return Center(
            child: InkWell(
              onTap: () {
                setState(() {
                  _loading = true;
                  _error = false;
                  fetchUsers();
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Error while loading users, tap to try again"),
              ),
            ));
      }
    } else {
      return ListView.separated(
          itemCount: _users.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _users.length - _nextPageThreshold) {
              fetchUsers();
            }
            if (index == _users.length) {
              if (_error) {
                return Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _loading = true;
                          _error = false;
                          fetchUsers();
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("Error while loading users, tap to try again"),
                      ),
                    ));
              } else {
                return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ));
              }
            }
            final User user = _users[index];
            return ListTile(
              leading: Image.network(user.avatarUrl),
              title: Text(user.username),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserInfo(
                      userName: user.username,
                    ),),);
              },
            );
          }, separatorBuilder: (BuildContext context, int index) {
            return Divider(color: Colors.black);
      },);
    }
    return Container();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(
          Uri.parse("https://api.github.com/users?per_page=$_perPage&since=$_userId"));
      List<User> fetchedUsers = User.parseList(json.decode(response.body));
      setState(() {
        _hasMore = fetchedUsers.length == defaultUsersPerPageCount;
        _loading = false;
        _pageNumber = _pageNumber + 1;
        _users.addAll(fetchedUsers);
        _userId = fetchedUsers[fetchedUsers.length - 1].id;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }  }

class User {
  final int id;
  final String username;
  final String avatarUrl;
  User(this.id, this.username, this.avatarUrl);
  factory User.fromJson(Map<String, dynamic> json) {
    return User(json["id"], json["login"], json["avatar_url"]);
  }
  static List<User> parseList(List<dynamic> list) {
    return list.map((i) => User.fromJson(i)).toList();
  }

  @override
  String toString() {
    return 'User: {name: $username, profile: $avatarUrl}';
  }
}

