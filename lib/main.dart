import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/Pages/HomeScreen/chatscreen.dart';
import 'package:talking_pigeon_x/Pages/SplashScreen/splashscreen.dart';
import 'package:talking_pigeon_x/Pages/lifecyclemanager.dart';

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String _username = (prefs.getString('username') ?? '');
  print(_username);
  runApp(LifeCycleManager(
    username: _username,
    child: MaterialApp(
        showPerformanceOverlay: false,
        home: _username != ""
            ? ChatScreenBuildContext(
                username: _username,
              )
            : SplashScreen()),
  ));
}

class ChatScreenBuildContext extends StatefulWidget {
  final String username;
  ChatScreenBuildContext({this.username});

  @override
  _ChatScreenBuildContextState createState() => _ChatScreenBuildContextState();
}

class _ChatScreenBuildContextState extends State<ChatScreenBuildContext> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(
      username: widget.username,
    );
  }
}
