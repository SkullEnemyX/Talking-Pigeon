import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/authentication.dart';
import 'splashscreen.dart';

void main() => runApp(new Talkingpigeon());

class Talkingpigeon extends StatefulWidget {
  @override
  _TalkingpigeonState createState() => _TalkingpigeonState();
}

class _TalkingpigeonState extends State<Talkingpigeon> {
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
  Widget build(BuildContext context) {
    return new SplashScreen();
  }
}
