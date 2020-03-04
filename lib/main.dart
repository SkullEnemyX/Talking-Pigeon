import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/Pages/Bloc/themebloc.dart';
import 'package:talking_pigeon_x/Pages/lifecyclemanager.dart';

import 'Pages/HomeScreen/chatscreen.dart';
import 'Pages/SplashScreen/splashscreen.dart';

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String _username = (prefs.getString('username') ?? '');
  bool darkThemeEnabled = prefs.getBool("DarkMode");
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(LifeCycleManager(
        username: _username,
        child: StreamBuilder(
            initialData: darkThemeEnabled ?? false,
            stream: bloc.darkThemeEnabled,
            builder: (context, snapshot) {
              return MaterialApp(
                  theme: ThemeData(
                    canvasColor: snapshot.data ? Colors.white : Colors.black,
                    backgroundColor:
                        snapshot.data ? Color(0xff242424) : Colors.white,
                    accentColor: Color(0xFF27E9E1),
                    cardColor: Colors.grey.shade800,
                    brightness:
                        snapshot.data ? Brightness.dark : Brightness.light,
                    appBarTheme: AppBarTheme(
                      color: snapshot.data ? Color(0xff242424) : Colors.white,
                      iconTheme: IconThemeData(
                        color: Color(0xFF27E9E1),
                        size: 25.0,
                      ),
                      elevation: 0.0,
                      textTheme: TextTheme(
                        title: TextStyle(
                          color: snapshot.data ? Colors.white : Colors.black,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    cursorColor: Colors.blue,
                    scaffoldBackgroundColor:
                        snapshot.data ? Color(0xff242424) : Colors.white,
                    textTheme: TextTheme(
                      title: TextStyle(
                        color: snapshot.data ? Colors.white : Colors.black,
                      ),
                      subtitle: TextStyle(
                        color: snapshot.data ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  home: _username != ""
                      ? ChatScreen(
                          username: _username,
                          darkThemeEnabled: snapshot.data,
                        )
                      : SplashScreen());
            })));
  });
}
