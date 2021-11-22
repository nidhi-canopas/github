import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class RepositoryInfo extends StatefulWidget {
  final String userName;

  const RepositoryInfo({Key? key, required this.userName}) : super(key: key);

  @override
  _RepositoryInfoState createState() => _RepositoryInfoState();
}

class _RepositoryInfoState extends State<RepositoryInfo> {
  late bool _error;
  late bool _loading;
  late List<UserRepo> repos;
  late bool _hasMore;
  final int _nextPageThreshold = 5;
  final recordsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _error = false;
    repos = [];
    _loading = true;
    _hasMore = true;

    fetchRepositories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repositories'),
      ),
      body: getBody(),
    );
  }

  Widget getBody() {
    if (repos.isEmpty) {
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
              fetchRepositories();
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
        itemCount: repos.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == repos.length - _nextPageThreshold) {
            fetchRepositories();
          }
          if (index == repos.length) {
            if (_error) {
              return Center(
                  child: InkWell(
                onTap: () {
                  setState(() {
                    _loading = true;
                    _error = false;
                    fetchRepositories();
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Error while loading repos, tap to try again"),
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
            // leading: Text(repo.name),
            title: Text(repo.name),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(color: Colors.black);
        },
      );
    }
    return Container();
  }

  Future<void> fetchRepositories() async {
    try {
      final response = await http.get(
          Uri.parse("https://api.github.com/users/${widget.userName}/repos"));
      List<UserRepo> fetchedRepos =
          UserRepo.parseList(json.decode(response.body));
      setState(() {
        _hasMore = fetchedRepos.length == recordsPerPage;
        _loading = false;
        repos.addAll(fetchedRepos);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
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

  UserRepo(
      this.name, this.fullName, this.private, this.htmlUrl, this.description);

  factory UserRepo.fromJson(Map<String, dynamic> json) {
    return UserRepo(json["name"], json["full_name"], json["private"],
        json["html_url"], json["description"]);
  }

  static List<UserRepo> parseList(List<dynamic> list) {
    return list.map((i) => UserRepo.fromJson(i)).toList();
  }

  @override
  String toString() {
    return 'User: {name: $name, desc: $description}';
  }
}
