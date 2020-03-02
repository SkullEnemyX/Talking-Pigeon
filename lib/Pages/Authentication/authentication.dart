import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UserData {
  String displayName;
  String email;
  String uid;
  String password;

  UserData({this.displayName, this.email, this.uid, this.password});
}

class Userauthentication {
  String message = "Account created successfully";
  Future<String> createUser(UserData userdata) async {
    FirebaseUser _auth =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: userdata.email,
      password: userdata.password,
    );
    return "${_auth.uid}";
  }

  Future<String> verifyuser(UserData userdata) async {
    FirebaseUser _auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userdata.email, password: userdata.password);
    return "${_auth.uid}";
  }

  logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
