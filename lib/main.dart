import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/Pages/Bloc/themebloc.dart';
import 'package:talking_pigeon_x/Pages/lifecyclemanager.dart';

import 'Pages/HomeScreen/chatscreen.dart';
import 'Pages/SplashScreen/splashscreen.dart';
import 'Pages/global_configurations/config.dart';

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String _username = (prefs.getString('username') ?? '');
  bool darkThemeEnabled = prefs.getBool(Config.darkModePrefs);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(LifeCycleManager(
        username: _username,
        child: StreamBuilder(
            initialData: darkThemeEnabled ?? false,
            stream: bloc.darkThemeEnabled,
            builder: (context, snapshot) {
              return MaterialApp(
                  theme: snapshot.data
                      ? ThemeData(
                          backgroundColor: Color(0xff242424),
                          accentColor: Color(0xFF27E9E1),
                          cardColor: Colors.grey.shade800,
                          appBarTheme: AppBarTheme(
                            color: Color(0xff242424),
                            iconTheme: IconThemeData(
                                color: Color(0xFF27E9E1), size: 25.0),
                            elevation: 0.0,
                            textTheme: TextTheme(
                              title: TextStyle(
                                color: Colors.white,
                                fontSize: 10.0,
                              ),
                            ),
                          ),
                          textTheme: TextTheme(
                            title: TextStyle(color: Colors.white),
                            subtitle: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ThemeData(
                          backgroundColor: Colors.white,
                          accentColor: Color(0xFF27E9E1),
                          cardColor: Colors.grey.shade100,
                          appBarTheme: AppBarTheme(
                            color: Colors.white,
                            iconTheme: IconThemeData(
                                color: Color(0xFF27E9E1), size: 25.0),
                            elevation: 0.0,
                            textTheme: TextTheme(
                              title: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                          textTheme: TextTheme(
                            title: TextStyle(color: Colors.black),
                            subtitle: TextStyle(color: Colors.grey),
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
