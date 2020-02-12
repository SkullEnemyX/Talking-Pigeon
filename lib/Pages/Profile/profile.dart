import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  final Color backgroundColor;
  final String username;
  Profile({@required this.username, this.backgroundColor});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: widget.backgroundColor,
      ),
    );
  }
}
