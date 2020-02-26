import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/Pages/HomeScreen/chatscreen.dart';
import 'authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  TabController tabController;
  TextEditingController tec;

  @override
  void initState() {
    tec = new TextEditingController();
    super.initState();
    tabController = new TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.teal),
      home: new Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: new AppBar(
            bottomOpacity: 0.7,
            title: new Text(
              "Talking Pigeon",
              style: TextStyle(
                fontSize: 25.0,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            bottom: new TabBar(
              controller: tabController,
              tabs: <Widget>[
                new Tab(
                  text: "Sign-up",
                ),
                new Tab(
                  text: "Sign-in",
                )
              ],
            ),
          ),
          key: scaffoldKey,
          backgroundColor: Colors.black,
          body: new Stack(fit: StackFit.expand, children: <Widget>[
            new Image(
                image: new AssetImage("assets/cherry.jpg"),
                fit: BoxFit.cover,
                color: Colors.black87,
                colorBlendMode: BlendMode.darken),
            new TabBarView(
              children: <Widget>[new Signup(), new Signin()],
              controller: tabController,
            ),
            //new Signup()
          ])),
    );
  }
}

//Signup Page
class Signup extends StatefulWidget {
  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> with SingleTickerProviderStateMixin {
  final formKey = new GlobalKey<FormState>();
  final Userauthentication userAuth = new Userauthentication();
  UserData userData = new UserData();
  String name;
  String username;
  var progress = 0;
  AnimationController _loginButtonController;
  Animation<double> buttonSqueezeAnimation;
  bool _isobs = true;
  Color _eyeBC = Colors.grey;
  List<String> people = [];

  @override
  void initState() {
    super.initState();
    _loginButtonController = new AnimationController(
        duration: new Duration(milliseconds: 1500), vsync: this);
    buttonSqueezeAnimation = new Tween(
      begin: 150.0,
      end: 100.0,
    ).animate(new CurvedAnimation(
        parent: _loginButtonController, curve: new Interval(0.0, 0.250)));
    _loginButtonController.addListener(() => this.setState(() {}));
  }

  @override
  void dispose() {
    _loginButtonController.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await _loginButtonController.forward();
      await _loginButtonController.reverse();
    } on TickerCanceled {}
  }

  Future<void> saveUserInfo(String username, String password) async {
    //Saving user's personal information on the device.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    prefs.setString('password', password);
  }

  void _submit() {
    final form = formKey.currentState;

    if (form.validate()) {
      form.save();
      performsignup();
    }
  }

  Future<int> addUserToPeopleDB() async {
    String message;
    int exist;
    await Firestore.instance
        .document("Users/${userData.uid}")
        .get()
        .then((onValue) {
      onValue.exists ? exist = 1 : exist = 0;
    });
    exist == 1
        ? message = "${userData.uid} already exists."
        : message = "Welcome, ${userData.uid}";
    final snackbar = new SnackBar(content: Text(message));
    Scaffold.of(context).showSnackBar(snackbar);
    return exist;
  }

  void performsignup() async {
    String _deviceID;
    List<String> error;
    final DocumentReference documentReference =
        Firestore.instance.document("Users/${userData.uid}");
    setState(() {
      _playAnimation();
    });

    FirebaseMessaging _message = FirebaseMessaging();
    await _message.getToken().then((token) {
      _deviceID = token;
    });

    if (userData.email != null &&
        userData.password != null &&
        userData.displayName != null) {
      int ifExist = await addUserToPeopleDB();
      if (ifExist == 0) {
        try {
          progress = 1;
          setState(() {});
          await userAuth.createUser(userData);
          Map<String, dynamic> userinfo = <String, dynamic>{
            "name": "${userData.displayName}",
            "username": "${userData.uid}",
            "email": "${userData.email}",
            "status": "online",
            "deviceId": _deviceID
          };
          documentReference
              .setData(userinfo)
              .whenComplete(() {})
              .catchError((e) => print(e));

          saveUserInfo(userData.uid, userData.password);
          DocumentReference people =
              Firestore.instance.document("People/People");
          List users;
          List finalUsers = [];
          await people.get().then((snapshot) {
            if (snapshot.exists) {
              users = snapshot.data["People"] ?? [];
            }
            users.forEach((name) => finalUsers.add(name));
          });
          finalUsers.add(userData.uid);
          await people.updateData({"People": finalUsers});
          Timer(
              Duration(milliseconds: 400),
              () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatScreen(
                            username: userData.uid,
                          ))));
        } catch (e) {
          setState(() {
            _playAnimation();
          });
          progress = 0;
          print('Error: $e');
          error = e.toString().split("(");
          error = error[1].toString().split(",");
          final snackbar2 = new SnackBar(
            content: Text(
                "Sign up failed because${error[1].toLowerCase().toString()}"),
          );
          Scaffold.of(context).showSnackBar(snackbar2);
        }
      }
    } else {
      progress = 0;
      setState(() {});
      final snackbar3 = new SnackBar(
        content: Text("Sign up failed!"),
      );
      Scaffold.of(context).showSnackBar(snackbar3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new ListView(
      shrinkWrap: true,
      children: <Widget>[
        new Container(
          //width: 110.0,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Padding(padding: const EdgeInsets.symmetric(vertical: 30.0)),
              new ClipRRect(
                borderRadius: new BorderRadius.circular(10.0),
                child: new Image(
                  image: new AssetImage("assets/logo.png"),
                  height: 80.0,
                  width: 80.0,
                ),
              ),
              new Padding(padding: const EdgeInsets.all(15.0)),
              new Text(
                "Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.0,
                  //fontWeight: FontWeight.bold,
                  fontFamily: 'beauty',
                  letterSpacing: 4,
                  wordSpacing: 3.0,
                ),
              ),
              new Padding(
                padding: const EdgeInsets.all(10.0),
              ),
              new Form(
                  key: formKey,
                  child: new Theme(
                    data: new ThemeData(
                        brightness: Brightness.dark,
                        primarySwatch: Colors.teal,
                        inputDecorationTheme: InputDecorationTheme(
                            labelStyle: new TextStyle(
                          color: Colors.teal,
                          fontSize: 13.0,
                        ))),
                    child: new Container(
                      padding: new EdgeInsets.symmetric(horizontal: 35.0),
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        //mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          new TextFormField(
                            decoration: new InputDecoration(labelText: "Name"),
                            validator: (val) =>
                                val.isEmpty || val.substring(0) == null
                                    ? 'Names field is empty'
                                    : null,
                            keyboardType: TextInputType.text,
                            onSaved: (val) => userData.displayName = val.trim(),
                          ),
                          new TextFormField(
                            decoration:
                                new InputDecoration(labelText: "User Name"),
                            keyboardType: TextInputType.text,
                            validator: (val) =>
                                val.isEmpty || val.substring(0) == null
                                    ? 'Password field is empty'
                                    : null,
                            onSaved: (val) => userData.uid = val.trim(),
                          ),
                          new TextFormField(
                            decoration: new InputDecoration(
                                labelText: "E-mail Address"),
                            validator: (val) =>
                                !val.contains('@') ? 'Invalid E-mail' : null,
                            keyboardType: TextInputType.emailAddress,
                            onSaved: (val) => userData.email = val.trim(),
                          ),
                          new TextFormField(
                            decoration: new InputDecoration(
                              labelText: "Password",
                              suffixIcon: IconButton(
                                onPressed: () {
                                  if (_isobs) {
                                    setState(() {
                                      _isobs = false;
                                      _eyeBC = Theme.of(context).primaryColor;
                                    });
                                  } else {
                                    setState(() {
                                      _isobs = true;
                                      _eyeBC = Colors.grey;
                                    });
                                  }
                                },
                                icon: Icon(
                                  Icons.remove_red_eye,
                                  color: _eyeBC,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.text,
                            validator: (val) =>
                                val.isEmpty || val.substring(0) == null
                                    ? 'Password field is empty'
                                    : null,
                            onSaved: (val) => userData.password = val.trim(),
                            obscureText: _isobs,
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(30.0),
                          ),
                          GestureDetector(
                            onTap: _submit,
                            child: new Container(
                              alignment: FractionalOffset.center,
                              child: buttonSqueezeAnimation.value > 120.0
                                  ? new Text(
                                      "Sign Up",
                                      style: new TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 0.3,
                                      ),
                                    )
                                  : new CircularProgressIndicator(
                                      valueColor:
                                          new AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                              width: buttonSqueezeAnimation.value,
                              height: 50.0,
                              decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(25.0)),
                            ),
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(20.0),
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(20.0),
                          ),
                        ],
                      ),
                    ),
                  ))
            ],
          ),
        ),
      ],
    );
  }
}

//Signin Page
class Signin extends StatefulWidget {
  @override
  _SigninState createState() => _SigninState();
}

class _SigninState extends State<Signin> with SingleTickerProviderStateMixin {
  final formKey = new GlobalKey<FormState>();
  AnimationController _loginButtonController;
  Animation<double> buttonSqueezeAnimation;
  bool _isobscured = true;
  Color _eyeButtonColor = Colors.grey;
  Userauthentication userAuth = new Userauthentication();
  UserData userData = new UserData();

  void initState() {
    super.initState();
    _loginButtonController = new AnimationController(
        duration: new Duration(milliseconds: 1500), vsync: this);
    buttonSqueezeAnimation = new Tween(
      begin: 150.0,
      end: 100.0,
    ).animate(new CurvedAnimation(
        parent: _loginButtonController, curve: new Interval(0.0, 0.250)));
    _loginButtonController.addListener(() => this.setState(() {}));
  }

  @override
  void dispose() {
    _loginButtonController.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await _loginButtonController.forward();
      await _loginButtonController.reverse();
    } on TickerCanceled {}
  }

  Future<void> saveUserInfo(String username, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    prefs.setString('password', password);
  }

  void _submit() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      performlogin();
    }
  }

  void performlogin() async {
    String _uid;
    List<String> error;
    setState(() {
      _playAnimation();
    });
    final DocumentReference documentReference =
        Firestore.instance.document("Users/${userData.uid}");

    await documentReference.get().then((snapshot) {
      if (snapshot.exists) {
        userData.email = snapshot.data['email'];
        userData.displayName = snapshot.data['name'];
      }
    });
    try {
      _uid = await userAuth.verifyuser(userData);
      String _deviceID;
      FirebaseMessaging _message = FirebaseMessaging();
      await _message.getToken().then((token) {
        _deviceID = token;
      });
      if (_uid != null) {
        final snackbar1 = new SnackBar(
          content: Text(
            "Welcome, ${userData.displayName}",
            textAlign: TextAlign.center,
          ),
        );
        saveUserInfo(userData.uid, userData.password);
        documentReference
            .updateData({"deviceId": _deviceID, "status": "online"});
        Scaffold.of(context).showSnackBar(snackbar1);
        Timer(
            Duration(milliseconds: 400),
            () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatScreen(
                          username: userData.uid,
                        ))));
      } else {
        setState(() {
          _playAnimation();
          final snackbar2 = new SnackBar(
            content: Text(
              "Sign in failed because your email is not verified.",
              textAlign: TextAlign.center,
            ),
          );
          Scaffold.of(context).showSnackBar(snackbar2);
        });
      }
    } catch (e) {
      setState(() {});
      error = e.toString().split("(");
      error = error[1].toString().split(",");
      final snackbar2 = new SnackBar(
        content: Text("Sign in failed!\nReason: ${error[1].toString()}"),
      );
      Scaffold.of(context).showSnackBar(snackbar2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new ListView(
      shrinkWrap: true,
      children: <Widget>[
        new Container(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              new Padding(padding: new EdgeInsets.symmetric(vertical: 30.0)),
              new ClipRRect(
                borderRadius: new BorderRadius.circular(10.0),
                child: new Image(
                  image: new AssetImage("assets/logo.png"),
                  height: 80.0,
                  width: 80.0,
                ),
              ),
              new Padding(padding: new EdgeInsets.all(20.0)),
              new Text(
                "Credentials",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.0,
                  //fontWeight: FontWeight.bold,
                  fontFamily: 'beauty',
                  letterSpacing: 4,
                  wordSpacing: 3.0,
                ),
              ),
              new Form(
                  key: formKey,
                  child: new Theme(
                    data: new ThemeData(
                        brightness: Brightness.dark,
                        primarySwatch: Colors.teal,
                        inputDecorationTheme: InputDecorationTheme(
                            labelStyle: new TextStyle(
                          color: Colors.teal,
                          fontSize: 13.0,
                        ))),
                    child: new Container(
                      padding: new EdgeInsets.all(40.0),
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          new TextFormField(
                            decoration:
                                new InputDecoration(labelText: "User Name"),
                            validator: (val) =>
                                val.isEmpty || val.substring(0) == null
                                    ? 'User Name field is empty'
                                    : null,
                            keyboardType: TextInputType.text,
                            onSaved: (val) => userData.uid = val,
                          ),
                          new TextFormField(
                            decoration: new InputDecoration(
                                labelText: "Password",
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    if (_isobscured) {
                                      setState(() {
                                        _isobscured = false;
                                        _eyeButtonColor =
                                            Theme.of(context).primaryColor;
                                      });
                                    } else {
                                      setState(() {
                                        _isobscured = true;
                                        _eyeButtonColor = Colors.grey;
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    Icons.remove_red_eye,
                                    color: _eyeButtonColor,
                                  ),
                                )),
                            keyboardType: TextInputType.text,
                            validator: (val) =>
                                val.isEmpty || val.substring(0) == null
                                    ? 'Password field is empty'
                                    : null,
                            onSaved: (val) => userData.password = val.trim(),
                            obscureText: _isobscured,
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(40.0),
                          ),
                          GestureDetector(
                            onTap: _submit,
                            child: new Container(
                              alignment: FractionalOffset.center,
                              child: buttonSqueezeAnimation.value > 120.0
                                  ? new Text(
                                      "Sign In",
                                      style: new TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 0.3,
                                      ),
                                    )
                                  : new CircularProgressIndicator(
                                      valueColor:
                                          new AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                              width: buttonSqueezeAnimation.value,
                              height: 50.0,
                              decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(25.0)),
                            ),
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(20.0),
                          ),
                          //progress!=1?Container():CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  ))
            ],
          ),
        ),
      ],
    );
  }
}
