import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:talking_pigeon_x/Pages/Authentication/authentication.dart';
import 'package:talking_pigeon_x/Pages/Authentication/sign-in.dart';
import 'package:talking_pigeon_x/Pages/ChatPage/chatpage.dart';
import 'package:talking_pigeon_x/Pages/HomeScreen/usersearch.dart';
import 'package:talking_pigeon_x/Pages/Profile/profile.dart';
import 'package:talking_pigeon_x/Pages/widgets/animated_bottombar.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendData {
  String username;
  String lastMessage;
  String timeStamp;
  FriendData(this.username, this.timeStamp, this.lastMessage);
}

class ChatScreen extends StatefulWidget {
  final String username;
  final bool darkThemeEnabled;
  ChatScreen({Key key, this.username, this.darkThemeEnabled}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //Make it dynamic
  String greeting = "Good Afternoon";
  String theme = "Dark Theme";
  int gvalue = 0;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  TextEditingController textEditingController = TextEditingController();
  int hour;
  int selectedIndex = 0;
  Userauthentication userAuth = new Userauthentication();
  UserData userData = new UserData();
  //bool loadingInProgress;
  String lastMessage = "";
  String friendid;
  String thumbnail = "";
  String profilepic = "";
  String fullname = "";
  Stream<QuerySnapshot> streamOfFriends;
  var childButtons = List<UnicornButton>();
  //Bottom Animated Bar
  //Ends here.

  @override
  void initState() {
    super.initState();
    _initx();
    //insertUnicornButtons();
    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
      print(message);
    }, onLaunch: (Map<String, dynamic> message) async {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatPage(
                    name: widget.username,
                    frienduid: message['data']['sendername'],
                  )));
      //print(message);
    }, onResume: (Map<String, dynamic> message) async {
      Navigator.of(context).popUntil((route) => route.isFirst);
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatPage(
                    name: widget.username,
                    frienduid: message['data']['sendername'],
                  )));
      //print(message);
    });
  }

  _initx() async {
    fetchTime();
    streamOfFriends = _fetchFromFriendsCollection();
    await Firestore.instance
        .document("Users/${widget.username}")
        .updateData({"status": "online"});
    userDetails();
  }

  userDetails() async {
    await Firestore.instance
        .document("Users/${widget.username}")
        .get()
        .then((onValue) {
      if (onValue.exists) {
        fullname = onValue.data["name"];
        thumbnail = onValue.data["thumbnail"];
        profilepic = onValue.data["profileImage"];
      }
    });
  }

  friendFetchQuerySnapshot(String groupID, DocumentReference reference) {
    Stream<QuerySnapshot> friendDocumentReference = reference
        .collection("$groupID")
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
    return friendDocumentReference;
  }

  returnGroupId(String myid, String friendid) {
    if (myid.hashCode >= friendid.hashCode) {
      return (myid.hashCode.toString() + friendid.hashCode.toString());
    } else {
      return (friendid.hashCode.toString() + myid.hashCode.toString());
    }
  }

  String customTimestamp(int timestamp) {
    var now = new DateTime.now();
    var format = new DateFormat('hh:mm a');
    var date = new DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 0 ||
        diff.inSeconds > 0 && diff.inMinutes == 0 ||
        diff.inMinutes > 0 && diff.inHours == 0 ||
        diff.inHours > 0 && diff.inDays == 0) {
      time = format.format(date);
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = 'Yesterday';
      } else {
        format = DateFormat("d/M/y");
        time = format.format(date);
      }
    }
    return time;
  }

  String readTimestamp(int timestamp) {
    var now = new DateTime.now();
    var format = new DateFormat('HH:mm a');
    var date = new DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 0 ||
        diff.inSeconds > 0 && diff.inMinutes == 0 ||
        diff.inMinutes > 0 && diff.inHours == 0 ||
        diff.inHours > 0 && diff.inDays == 0) {
      time = 'Today at ' + format.format(date);
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = 'Yesterday at ' + format.format(date);
      } else {
        format = DateFormat("HH:mm a on MMM d, y");
        time = format.format(date);
      }
    }
    return time;
  }

  fetchData() {
    Stream<QuerySnapshot> snapshot = Firestore.instance
        .collection("Users")
        .where('username', isEqualTo: widget.username)
        .snapshots();
    return snapshot;
  }

  Stream<QuerySnapshot> _fetchFromFriendsCollection() {
    Stream<QuerySnapshot> snapshot = Firestore.instance
        .collection("FriendList")
        .document("FriendList")
        .collection(widget.username)
        .orderBy("lastTimestamp", descending: true)
        .snapshots();
    return snapshot;
  }

  //Returns a widget that formats the last sent message.
  Widget formatLastMessage(String string, TextStyle style) {
    if (string.isEmpty) {
      return Text(
        "*No new messages*",
        style: style,
      );
    } else if (string.contains("https://i.ibb.co/")) {
      return Row(
        children: <Widget>[
          Icon(
            Icons.image,
            color: Theme.of(context).iconTheme.color,
          ),
          SizedBox(
            width: 5.0,
          ),
          Text(
            "Photo",
            style: style,
          )
        ],
      );
    } else if (string.split(" ").length < 8) {
      return Text(
        string,
        style: style,
      );
    }
    return Text(
      string.split(" ").sublist(0, 8).join(" ") + " ...",
      style: style,
    );
  }

  String fetchInitials(String s) {
    //Temporary function in case user's profile picture is used instead of their initials.
    return s[0][0].toUpperCase();
  }

  Widget _buildBody(int selection) {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: new Column(
        children: <Widget>[
          new Padding(padding: EdgeInsets.only(top: 10.0)),
          Row(
            children: <Widget>[
              new Padding(padding: EdgeInsets.only(left: 25.0)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(
                    "$greeting, " +
                        "${widget.username}".toString().split(" ")[0],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25.0,
                      color: Theme.of(context).textTheme.title.color,
                    ),
                  ),
                  new Padding(
                    padding: EdgeInsets.only(top: 5.0, left: 30.0),
                  ),
                ],
              ),
            ],
          ),
          new Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: streamOfFriends,
                  builder: (context, snap) {
                    return !snap.hasData
                        ? Center(child: Container())
                        : ListView.builder(
                            itemCount: snap.data.documents?.length ?? 0,
                            itemBuilder: (context, index) {
                              DocumentReference ref =
                                  snap.data.documents[index]["conversation"];
                              String friendUsername =
                                  snap.data.documents[index]["username"];
                              return StreamBuilder<QuerySnapshot>(
                                  stream: friendFetchQuerySnapshot(
                                      returnGroupId(
                                          widget.username, friendUsername),
                                      ref),
                                  builder: (BuildContext context,
                                      AsyncSnapshot snapshot) {
                                    if (snapshot.hasData) {
                                      List<DocumentSnapshot> documents =
                                          snapshot.data.documents;
                                      return ListTile(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChatPage(
                                                        name: widget.username,
                                                        frienduid:
                                                            friendUsername,
                                                      )));
                                        },
                                        title: Text(
                                          friendUsername,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .title
                                                  .color,
                                              fontSize: 20.0,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Container(
                                            padding: EdgeInsets.only(top: 5.0),
                                            child: formatLastMessage(
                                              documents.isNotEmpty
                                                  ? documents[0]["content"]
                                                  : "*no new messages*",
                                              TextStyle(
                                                color: Colors.grey,
                                                fontSize: 15.0,
                                              ),
                                            )),
                                        trailing: snapshot
                                                .data.documents.isEmpty
                                            ? Text(" ")
                                            : Text(
                                                documents.isNotEmpty
                                                    ? customTimestamp(int.parse(
                                                        documents[0]
                                                                ["timestamp"] ??
                                                            ""))
                                                    : "",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .title
                                                      .color,
                                                  fontSize: 13.0,
                                                ),
                                              ),
                                        leading: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 2.0,
                                                color: Color(0xFF27E9E1),
                                              ),
                                              shape: BoxShape.circle),
                                          child: new CircleAvatar(
                                            radius: 25.0,
                                            backgroundColor: Theme.of(context)
                                                .backgroundColor,
                                            foregroundColor: Color(0xFF27E9E1),
                                            child: Text(
                                              fetchInitials(friendUsername),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20.0),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return Container();
                                  });
                            },
                          );
                  }))
        ],
      ),
    );
    // }
  }

  fetchTime() {
    DateTime now = DateTime.now();
    hour = int.parse(DateFormat('kk').format(now));

    if (hour >= 0 && hour < 12) {
      greeting = "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }
    if (hour < 17) {
      gvalue = 1;
    } else {
      gvalue = 0;
    }
  }

  // void darkTheme() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String _theme = (prefs.getString("theme") ?? "Light");
  //   print(_theme);
  //   setState(() {
  //     if (_theme.compareTo("Dark") == 0) {
  //       greet = Colors.white;
  //       background = Color(0xFF242424);
  //       theme = "Light Theme";
  //       gvalue = 1;
  //     } else {
  //       greet = Color(0xFF242424);
  //       background = Colors.white;
  //       theme = "Dark Theme";
  //       gvalue = 0;
  //     }
  //   });
  // }

  void menuList(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == 'a') {
      // darkTheme();
      // String _theme = (prefs.getString("theme") ?? "Light");
      // _theme.compareTo("Light") == 0
      //     ? prefs.setString("theme", "Dark")
      //     : prefs.setString("theme", "Light");
    } else if (value == 'b') {
      userAuth.logout();
      prefs.setString('username', '');
      prefs.setString('password', '');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } else if (value == 'c') {
      exit(0);
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();

    super.dispose();
  }

  final List<BarItem> barItems = [
    BarItem(
      text: "Personal",
      iconData: Icons.chat_bubble_outline,
      color: Colors.indigo,
    ),
    BarItem(
      text: "Groups",
      iconData: Icons.people,
      color: Colors.pinkAccent,
    ),
    BarItem(
      text: "Search",
      iconData: Icons.search,
      color: Colors.yellow.shade900,
    ),
    BarItem(
      text: "Profile",
      iconData: Icons.person_outline,
      color: Colors.teal,
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      body: IndexedStack(
        index: selectedIndex,
        children: <Widget>[
          _buildBody(0),
          Container(
            child: Center(
              child: Text(
                "Group Chat coming soon...",
                style:
                    TextStyle(color: Theme.of(context).textTheme.title.color),
              ),
            ),
          ),
          Container(),
          Profile(
            username: widget.username,
            darkThemeEnabled: widget.darkThemeEnabled,
          ),
        ],
      ),
      bottomNavigationBar: AnimatedBottomBar(
        onBarTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        barItems: barItems,
        animationDuration: const Duration(milliseconds: 150),
        barStyle: BarStyle(fontSize: 15.0, iconSize: 30.0),
      ),
      appBar: new AppBar(
        backgroundColor: Theme.of(context).appBarTheme.color,
        centerTitle: true,
        title: Text(
          "Talking Pigeon",
          style: TextStyle(
            color: Theme.of(context).textTheme.title.color,
            fontSize: 25.0,
          ),
        ),
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.search,
                size: 30.0,
                color: Color(0xFF27E9E1),
              ),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: UserSearch(
                    widget.username,
                  ),
                );
              })
        ],
      ),
    );
  }
}
