import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:talking_pigeon_x/authentication.dart';
import 'package:talking_pigeon_x/chatscreen.dart';
import 'package:talking_pigeon_x/sign-in.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool credentialCorrectness = false;
  String _username;
  UserData userData = UserData();

  Future infoAvailable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Userauthentication userAuth = Userauthentication();
    String _uid;
    _username = (prefs.getString('username') ?? '');
    String _password = (prefs.getString('password') ?? '');
    if (_username != '' && _password != '') {
      await Firestore.instance
          .document("Users/$_username")
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          userData.email = snapshot.data['email'];
          userData.password = _password;
          userData.uid = _username;
        }
      });
      try {
        _uid = await userAuth.verifyuser(userData);
        if (_uid != null) {
          setState(() {
            credentialCorrectness = true;
          });
        }
      } catch (e) {
        throw e;
      }
    } else {
      setState(() {
        credentialCorrectness = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    infoAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "The Talking Pigeon",
      debugShowCheckedModeBanner: false,
      home: SplashWallpaper(
        credentialsCorrect: credentialCorrectness,
        username: credentialCorrectness ? userData.uid : '',
      ),
    );
  }
}

class SplashWallpaper extends StatefulWidget {
  final bool credentialsCorrect;
  final String username;
  SplashWallpaper({this.credentialsCorrect = false, @required this.username});
  @override
  _SplashWallpaperState createState() => _SplashWallpaperState();
}

class _SplashWallpaperState extends State<SplashWallpaper>
    with SingleTickerProviderStateMixin {
  AnimationController _iconAnimationController;
  Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = new AnimationController(
        vsync: this, duration: new Duration(milliseconds: 4000));
    _iconAnimation = new CurvedAnimation(
        parent: _iconAnimationController, curve: Curves.bounceOut);
    _iconAnimation.addListener(() => this.setState(() {}));
    _iconAnimationController.forward();
    Timer(
        Duration(seconds: 5),
        () => Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => widget.credentialsCorrect
                ? ChatScreen(
                    username: widget.username,
                  )
                : LoginScreen())));
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            child: new Image(
              image: new AssetImage("assets/wally-1.jpg"),
              fit: BoxFit.cover,
              color: Colors.black54,
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                      ),
                      CircleAvatar(
                        child: new Image(
                          image: new AssetImage("assets/logo.png"),
                          width: _iconAnimation.value * 100,
                          height: _iconAnimation.value * 100,
                        ),
                        radius: 70.0,
                        backgroundColor: Color(0xFF27E9E1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                      ),
                      new Text(
                        "The Talking Pigeon",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30.0,
                            color: Colors.white,
                            fontFamily: 'cassandra',
                            letterSpacing: 2.0),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: new Container(
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                      ),
                      SpinKitCircle(
                        size: 35.0,
                        color: Colors.white,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                      ),
                      Text(
                        "Made with love in India",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'tomatoes',
                          fontSize: 17.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                      )
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
//Completed but animation on icon and page animation can be added.
