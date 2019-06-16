import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:talking_pigeon_x/chatscreen.dart';
import 'authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Talking Pigeon",
      theme: new ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: new LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
    return new Scaffold(
        appBar: new AppBar(
          bottomOpacity: 0.7,
          centerTitle: true,
          title: new Text(
            "The Talking Pigeon",
            style: TextStyle(
              fontFamily: 'beauty',
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
        ]));
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
        duration: new Duration(milliseconds: 3000), vsync: this);
    buttonSqueezeAnimation = new Tween(
      begin: 60.0,
      end: 20.0,
    ).animate(new CurvedAnimation(
        parent: _loginButtonController, curve: new Interval(0.0, 0.250)));
  }

  @override
  void dispose() {
    _loginButtonController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = formKey.currentState;

    if (form.validate()) {
      form.save();
      performsignup();
    }
  }

  Future<int> addUserToPeopleDB() async {
    var temp;
    int ifExist = 1;
    //Checking condition whether the username exists already, firebase automatically checks whether the email is already used.
    DocumentReference peopleDocument =
        Firestore.instance.document("People/People");
    await peopleDocument.get().then((snapshot) {
      ifExist = snapshot.data.values.toList()[0].contains(userData.uid)?1:0;
      if (ifExist == 1) {
        final snackbar1 = new SnackBar(
          content: Text(
              "Username: ${userData.uid} already exists, please choose another one."),
        );
        Scaffold.of(context).showSnackBar(snackbar1);
      } 
      else {
        //Code written below enters the users info into the People's database which consists of the list of user Talking Pigeon has.
        var people = snapshot.data["People"].toList();
        people.add("${userData.uid}"); //Add here what new content wants to be added.
        Map<String, dynamic> peopledata = <String, dynamic>{
          "People": people,
        };
        print(people);
        peopleDocument.updateData(peopledata).whenComplete((){
          print("User appended");
        });
      }
    });
    return ifExist;
  }

  void performsignup() async {
    final DocumentReference documentReference =
        Firestore.instance.document("Users/${userData.uid}");
    List<String> error;
    if (userData.email != null && userData.password != null && userData.displayName != null) {
      int ifExist = await addUserToPeopleDB();
      if(ifExist == 0){
      try {
        progress = 1;
        setState(() {});
        await userAuth.createUser(userData);
        Map<String, dynamic> userinfo = <String, dynamic>{
          "name": "${userData.displayName}",
          "username": "${userData.uid}",
          "email": "${userData.email}",
          "friends": []
        };
        documentReference.setData(userinfo).whenComplete(() {
         final snackbar1 = new SnackBar(
          content: Text(
              "Welcome, ${userData.displayName}"), //replace name with database name.
        );
        Scaffold.of(context).showSnackBar(snackbar1);
        }).catchError((e) => print(e));
        
        Timer(
            Duration(milliseconds: 400),
            () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatScreen(
                          username: userData.uid,
                        ))));
      } catch (e) {
        progress = 0;
        setState(() {});
        print('Error: $e');
        error = e.toString().split("(");
        error = error[1].toString().split(",");
        final snackbar2 = new SnackBar(
          content: Text("Sign up failed because${error[1].toLowerCase().toString()}"),
        );
        Scaffold.of(context).showSnackBar(snackbar2);
      }}
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
                "Your details ?",
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontFamily: 'beauty',
                  letterSpacing: 3.0,
                  wordSpacing: 6.0,
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
                            onSaved: (val) => userData.displayName = val,
                          ),
                          new TextFormField(
                            decoration:
                                new InputDecoration(labelText: "User Name"),
                            keyboardType: TextInputType.text,
                            validator: (val) =>
                                val.isEmpty || val.substring(0) == null
                                    ? 'Password field is empty'
                                    : null,
                            onSaved: (val) => userData.uid = val,
                          ),
                          new TextFormField(
                            decoration: new InputDecoration(
                                labelText: "E-mail Address"),
                            validator: (val) =>
                                !val.contains('@') ? 'Invalid E-mail' : null,
                            keyboardType: TextInputType.emailAddress,
                            onSaved: (val) => userData.email = val,
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
                            onSaved: (val) => userData.password = val,
                            obscureText: _isobs,
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(15.0),
                          ),
                          new RaisedButton(
                            onPressed: _submit,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40.0, vertical: 10.0),
                            child: new Text("Sign up"),
                            highlightColor: Colors.red,
                            splashColor: Colors.white,
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(20.0)),
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(20.0),
                          ),
                          progress != 1
                              ? Container()
                              : CircularProgressIndicator(
                                  strokeWidth: 5.0,
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
        duration: new Duration(milliseconds: 3000), vsync: this);
    buttonSqueezeAnimation = new Tween(
      begin: 70.0,
      end: 10.0,
    ).animate(new CurvedAnimation(
        parent: _loginButtonController, curve: new Interval(0.0, 0.250)));
    _loginButtonController.addListener(() => this.setState(() {}));
  }

  @override
  void dispose() {
    _loginButtonController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
    }
    performlogin();
    setState(() {});
  }

  void performlogin() async {
    String _uid;
    List<String> error;
    final DocumentReference documentReference =
        Firestore.instance.document("Users/${userData.uid}");
    final snackbar1 = new SnackBar(
      content: Text("Sign in successful :)"),
    );
    await documentReference.get().then((snapshot) {
      if (snapshot.exists) {
        userData.email = snapshot.data['email'];
      }
    });
    try {
      setState(() {});
      _uid = await userAuth.verifyuser(userData);
      //print(_uid);
      if (_uid != null) {
        Scaffold.of(context).showSnackBar(snackbar1);
        Timer(
            Duration(milliseconds: 400),
            () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatScreen(
                          username: userData.uid,
                        ))));
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
                "Log in and continue...",
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  //fontWeight: FontWeight.bold,
                  fontFamily: 'beauty',
                  letterSpacing: 2.5,
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
                            onSaved: (val) => userData.password = val,
                            obscureText: _isobscured,
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(40.0),
                          ),
                          new RaisedButton(
                            onPressed: () {
                              _submit();
                            },
                            padding: EdgeInsets.symmetric(
                                horizontal: buttonSqueezeAnimation.value,
                                vertical: 10.0),
                            child: buttonSqueezeAnimation.value > 40.0
                                ? new Text(
                                    "Sign In",
                                    style: new TextStyle(
                                      color: Colors.white,
                                    ),
                                  )
                                : new CircularProgressIndicator(
                                    valueColor:
                                        new AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                    strokeWidth: 2.0,
                                  ),
                            highlightColor: Colors.red,
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(25.0)),
                            splashColor: Colors.white,
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
