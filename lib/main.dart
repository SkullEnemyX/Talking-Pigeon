import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/chatscreen.dart';
import 'splashscreen.dart';

void main() {
  Talkingpigeon talkingpigeon = Talkingpigeon();
  talkingpigeon.infoAvailable().then((val) {
    if (val == "") {
      runApp(SplashScreen());
    } else {
      runApp(ChatScreenBuildContext(
        username: val,
      ));
    }
  });
}

class Talkingpigeon extends StatelessWidget {
  Future<String> infoAvailable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _username;
    _username = (prefs.getString('username') ?? '');
    String _password = (prefs.getString('password') ?? '');
    if (_username != '' && _password != '') {
      //Saving credentials like username and/or password only if previous signin/signup was successful.
      return _username;
      //   await Firestore.instance
      //       .document("Users/$_username")
      //       .get()
      //       .then((snapshot) {
      //     if (snapshot.exists) {
      //       userData.email = snapshot.data['email'];
      //       userData.password = _password;
      //       userData.uid = _username;
      //     }
      //   });
      //   try {
      //     _uid = await userAuth.verifyuser(userData);
      //     if (_uid != null) {
      //       setState(() {
      //         credentialCorrectness = true;
      //       });
      //     }
      //   } catch (e) {
      //     throw e;
      //   }
      // } else {
      //   setState(() {
      //     credentialCorrectness = false;
      //   });
      // }
    } else {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class ChatScreenBuildContext extends StatelessWidget {
  final String username;
  ChatScreenBuildContext({this.username});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(
        username: username,
      ),
    );
  }
}
