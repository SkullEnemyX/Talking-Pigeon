import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign-in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "The Talking Pigeon",
      debugShowCheckedModeBanner: false,
      home: new SplashWallpaper(),
      routes: <String, WidgetBuilder>{
        "/sign": (BuildContext context) => new HomeScreen(),
        "/splash": (BuildContext context) => new SplashScreen()
      },
    );
  }
}

class SplashX extends StatefulWidget {
  @override
  _SplashXState createState() => _SplashXState();
}

class _SplashXState extends State<SplashX> {
  Future checkSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      Navigator.of(context).pushReplacementNamed("/splash");
    } else {
      prefs.setBool('seen', true);
      Navigator.of(context).pushNamed("/sign");
    }
  }

  @override
  void initState() {
    super.initState();
    checkSeen();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold();
  }
}

class SplashWallpaper extends StatefulWidget {
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
    Timer(Duration(seconds: 3),
        () => Navigator.of(context).pushReplacementNamed("/sign"));
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
