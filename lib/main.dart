import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
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
  late int _skip = 0;
  @override
  void initState() {
    super.initState();
    _hasMore = true;
    _pageNumber = 1;
    _perPage = 50;
    _error = false;
    _loading = true;
    _users = [];
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
      return ListView.builder(
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
            return Card(
              child: Column(
                children: <Widget>[
                  Image.network(
                    user.avatarUrl,
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    height: 160,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(user.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          });
    }
    return Container();
  }

  Future<void> fetchUsers() async {
    try {
      log("page number $_pageNumber");
      log("next page threshold $_nextPageThreshold");
      final response = await http.get(
          Uri.parse("https://api.github.com/users?page=$_pageNumber&per_page=$_perPage"));
      List<User> fetchedUsers = _pageNumber > 1 ? User.parseList(json.decode(response.body)).sublist(_skip, 49) : User.parseList(json.decode(response.body));
      // print(fetchedUsers[49]);
      setState(() {
        _hasMore = fetchedUsers.length == defaultUsersPerPageCount;
        _loading = false;
        _pageNumber = _pageNumber + 1;
        _skip = _skip + 50;
        _users.addAll(fetchedUsers);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }  }

class User {
  final String username;
  final String avatarUrl;
  User(this.username, this.avatarUrl);
  factory User.fromJson(Map<String, dynamic> json) {
    return User(json["login"], json["avatar_url"]);
  }
  static List<User> parseList(List<dynamic> list) {
    return list.map((i) => User.fromJson(i)).toList();
  }

  @override
  String toString() {
    return 'User: {name: $username, profile: $avatarUrl}';
  }
}

