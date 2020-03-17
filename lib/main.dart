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
  Color themeColor = Color(prefs.getInt('color') ?? Colors.blue.value);
  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //   statusBarColor: Colors.black, // status bar color
  //   statusBarIconBrightness: Brightness.dark,
  // ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(LifeCycleManager(
        username: _username,
        child: StreamBuilder(
            initialData: darkThemeEnabled ?? false,
            stream: bloc.darkThemeEnabled,
            builder: (context, snapshot) {
              return StreamBuilder<Color>(
                  initialData: themeColor,
                  stream: colorBloc.colorTheme,
                  builder: (context, snap) {
                    return MaterialApp(
                        theme: ThemeData(
                          primarySwatch: Colors.teal,
                          canvasColor:
                              snapshot.data ? Colors.white : Colors.black,
                          backgroundColor:
                              snapshot.data ? Color(0xff242424) : Colors.white,
                          primaryColor: snap.data,
                          cardColor: Colors.grey.shade800,
                          iconTheme: IconThemeData(
                            color: snapshot.data ? Colors.white : Colors.black,
                          ),
                          buttonColor:
                              snapshot.data ? Colors.white12 : Colors.white54,
                          appBarTheme: AppBarTheme(
                            color: snapshot.data
                                ? Color(0xff242424)
                                : Colors.white,
                            iconTheme: IconThemeData(
                              color: snap.data,
                              size: 25.0,
                            ),
                            elevation: 0.0,
                            textTheme: TextTheme(
                              button: TextStyle(
                                color:
                                    snapshot.data ? Colors.white : Colors.black,
                              ),
                              title: TextStyle(
                                color:
                                    snapshot.data ? Colors.white : Colors.black,
                                fontSize: 15.0,
                              ),
                            ),
                          ),
                          cursorColor: Colors.blue,
                          scaffoldBackgroundColor:
                              snapshot.data ? Color(0xff242424) : Colors.white,
                          textTheme: TextTheme(
                            title: TextStyle(
                              color:
                                  snapshot.data ? Colors.white : Colors.black,
                            ),
                            subtitle: TextStyle(
                              color:
                                  snapshot.data ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        home: _username != ""
                            ? ChatScreen(
                                username: _username,
                                darkThemeEnabled: snapshot.data,
                              )
                            : SplashScreen());
                  });
            })));
  });
}
