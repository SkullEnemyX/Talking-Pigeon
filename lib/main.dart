import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/chatscreen.dart';
import 'splashscreen.dart';

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String _username = (prefs.getString('username') ?? '');
  print(_username);
  runApp(MaterialApp(
      home: _username != ""
          ? ChatScreenBuildContext(
              username: _username,
            )
          : SplashScreen()));
}

class ChatScreenBuildContext extends StatelessWidget {
  final String username;
  ChatScreenBuildContext({this.username});
  @override
  Widget build(BuildContext context) {
    return ChatScreen(
      username: username,
    );
  }
}
