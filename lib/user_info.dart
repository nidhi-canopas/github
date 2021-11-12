import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class UserInfo extends StatefulWidget {

  final String user_name;

  UserInfo(
      { Key? key, required this.user_name})
      : super(key: key);

  @override
  _UserInfoState createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  // late String _username;
  var _userInfo;
  var loading;
  var error;
  late bool repoError;
  late List<UserRepo> repos;
  late bool _repoLoading;
  late bool _hasMoreRepo;
  final int _nextPageGap = 5;

  @override
  void initState() {
    super.initState();
    // _username = "test";
    _userInfo = {};
    loading = true;
    error = false;
    repos = [];
    _repoLoading = true;
    repoError = false;
    _hasMoreRepo = true;

    fetchUserInfo();
    fetchUserRepositories();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      // print("_username :");
      // print(widget.user_name);
      // _username = widget.user_name;
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(_userInfo["login"]),
        automaticallyImplyLeading: false,
      ),
      body: /*Column(
        children: [
          Image.network(_userInfo["avatar_url"],
            height: 200,
            width: double.infinity,
            // color: Colors.black,
          ),
          Text(widget.user_name),
          RaisedButton(
              color: Colors.grey,
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back'))
        ],)*/Column(
          children: <Widget>[
            Expanded(
                child: Container(
                  color: Colors.green,
                  padding: const EdgeInsets.all(20.0),
                  margin: const EdgeInsets.all(10.0),
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 35,
                    child: ClipOval(
                      child:
                        Image.network(_userInfo["avatar_url"],
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        ),
                    ),
                  ),
                )
            ),
            Container(
                height: 40,
                // color: Colors.grey,
                margin: const EdgeInsets.all(10.0),
                child: Center(
                  child: new Text("Repositories",
                    style: new TextStyle(
                      fontSize: 20.0,
                      color: Colors.green,
                      fontWeight: FontWeight.w800, // light
                    ),
                  ),),
    ),
            Expanded(
                child: getBody()/*Container(
                  margin: const EdgeInsets.all(10.0),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    color: Colors.blueGrey,
                  ),
                )*/
            ),
          ]
      ),);}
      
      Widget getBody() {
    if (repos.length == 0 ) {
      if (_repoLoading) {
        print("repos are empty");
        return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ));
      } else if (repoError) {
        print("repos are empty");

        return Center(
            child: InkWell(
              onTap: () {
                setState(() {
                  _repoLoading = true;
                  repoError = false;
                  fetchUserRepositories();
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Error while loading repositories, tap to try again"),
              ),
            ));
      }
    } else {
      return ListView.separated(
        itemCount: repos.length + (_hasMoreRepo ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == repos.length - _nextPageGap) {
            fetchUserRepositories();
          }
          if (index == repos.length) {
            if (repoError) {
              return Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _repoLoading = true;
                        repoError = false;
                        fetchUserRepositories();
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
          final UserRepo repo = repos[index];
          return ListTile(
            // leading: Image.network(user.avatarUrl),
            title: Text(repo.name)
          );
        }, separatorBuilder: (BuildContext context, int index) {
        return Divider(color: Colors.black);
      },);
    }
        return Container();
      }
      
  Future<void> fetchUserInfo() async {
    // print("username :" + widget.user_name);
    try {
      final username = widget.user_name;
      final response = await http.get(
          Uri.parse("https://api.github.com/users/$username"));
     Map<String, dynamic> result = json.decode(response.body);
      // print("List Size: ${inspect(result)}");
      setState(() {
        _userInfo = result;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  Future<void> fetchUserRepositories() async {
    print("username :" + widget.user_name);
    try {
      print("inside try");
      final username = widget.user_name;
      final response = await http.get(
          Uri.parse("https://api.github.com/users/$username/repos"));
      // List<Map<String, dynamic>> result = json.decode(response.body);
      List<UserRepo> fetchedRepos = UserRepo.parseList(json.decode(response.body));
      print("repo list Size: ${inspect(fetchedRepos)}");
      print("repo length : ");
      print(fetchedRepos.length);
      setState(() {
        repos = fetchedRepos;
      });
    } catch (e) {
      setState(() {
        _repoLoading = false;
        repoError = true;
      });
    }
  }
}

class UserRepo {
  final String name;
  final String fullName;
  final bool private;
  final String htmlUrl;
  final String description;

  UserRepo(this.name, this.fullName, this.private, this.htmlUrl, this.description);
  factory UserRepo.fromJson(Map<String, dynamic> json) {
    return UserRepo(json["name"], json["full_name"], json["private"], json["html_url"], json["description"]);
  }
  static List<UserRepo> parseList(List<dynamic> list) {
    return list.map((i) => UserRepo.fromJson(i)).toList();
  }

  @override
  String toString() {
    return 'User: {name: $name, desc: $description}';
  }
}