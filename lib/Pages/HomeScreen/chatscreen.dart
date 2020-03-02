import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:talking_pigeon_x/Pages/Authentication/authentication.dart';
import 'package:talking_pigeon_x/Pages/Authentication/sign-in.dart';
import 'package:talking_pigeon_x/Pages/ChatPage/chatpage.dart';
import 'package:talking_pigeon_x/Pages/Profile/profile.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var globalUsername;
Color greet = Color(0xff242424);
Color background = Colors.white;

class FriendData {
  String username;
  String lastMessage;
  String timeStamp;
  FriendData(this.username, this.timeStamp, this.lastMessage);
}

class ChatScreen extends StatefulWidget {
  final String username;
  ChatScreen({Key key, this.username}) : super(key: key);
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
    _addNavBarButtons();
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
                    greet: greet,
                    background: background,
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
                    greet: greet,
                    background: background,
                  )));
      //print(message);
    });
  }

  _initx() async {
    fetchTime();
    darkTheme();
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
  Widget formatLastMessage(String string, TextStyle style, Color greet) {
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
            color: greet,
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
      color: background,
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
                      color: greet,
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
                                                        greet: greet,
                                                        background: background,
                                                      )));
                                        },
                                        title: Text(
                                          friendUsername,
                                          style: TextStyle(
                                              color: greet,
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
                                                greet)),
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
                                                    color: greet,
                                                    fontSize: 13.0),
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
                                            backgroundColor: background,
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

  void darkTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _theme = (prefs.getString("theme") ?? "Light");
    print(_theme);
    setState(() {
      if (_theme.compareTo("Dark") == 0) {
        greet = Color(0xFFFFFFFF);
        background = Color(0xFF242424);
        theme = "Light Theme";
        gvalue = 1;
      } else {
        greet = Color(0xFF242424);
        background = Color(0xFFFFFFF);
        theme = "Dark Theme";
        gvalue = 0;
      }
    });
  }

  void menuList(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == 'a') {
      darkTheme();
      String _theme = (prefs.getString("theme") ?? "Light");
      _theme.compareTo("Light") == 0
          ? prefs.setString("theme", "Dark")
          : prefs.setString("theme", "Light");
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

  // insertUnicornButtons() {
  //   childButtons.add(UnicornButton(
  //       hasLabel: true,
  //       labelText: "Create a team",
  //       currentButton: FloatingActionButton(
  //         heroTag: "train",
  //         backgroundColor: Colors.redAccent,
  //         mini: true,
  //         child: Icon(Icons.group),
  //         onPressed: () {
  //           showDialog(
  //               context: context,
  //               builder: (BuildContext context) {
  //                 return AlertDialog(
  //                   title: Text("What is your team called?"),
  //                   content: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: <Widget>[
  //                       TextField(
  //                         controller: textEditingController,
  //                         autofocus: true,
  //                       ),
  //                       SizedBox(
  //                         height: 15.0,
  //                       ),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                         children: <Widget>[
  //                           Material(
  //                             color: Colors.transparent,
  //                             child: InkWell(
  //                               onTap: () {
  //                                 Navigator.of(context).pop();
  //                                 textEditingController.clear();
  //                               },
  //                               child: Container(
  //                                 padding: const EdgeInsets.symmetric(
  //                                     vertical: 8.0, horizontal: 12.0),
  //                                 decoration: BoxDecoration(
  //                                     color: Colors.grey.shade300,
  //                                     borderRadius:
  //                                         BorderRadius.circular(12.0)),
  //                                 child: Text(
  //                                   "Cancel",
  //                                   style: TextStyle(
  //                                     color: greet,
  //                                     fontSize: 15.0,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           Material(
  //                             color: Colors.transparent,
  //                             child: InkWell(
  //                               onTap: () {
  //                                 Navigator.of(context).pop();
  //                                 String groupId = DateTime.now()
  //                                     .millisecondsSinceEpoch
  //                                     .toString();
  //                                 Navigator.of(context)
  //                                     .push(MaterialPageRoute(
  //                                         builder: (context) => GroupChat(
  //                                               groupName: textEditingController
  //                                                   .value.text,
  //                                               admin: globalUsername,
  //                                               greet: greet,
  //                                               groupId: groupId,
  //                                               background: background,
  //                                               username: globalUsername,
  //                                             )))
  //                                     .whenComplete(() {
  //                                   textEditingController.clear();
  //                                 });
  //                               },
  //                               child: Container(
  //                                 padding: const EdgeInsets.symmetric(
  //                                     vertical: 8.0, horizontal: 12.0),
  //                                 decoration: BoxDecoration(
  //                                     color: Color(0xFF27E9E1),
  //                                     borderRadius:
  //                                         BorderRadius.circular(12.0)),
  //                                 child: Text(
  //                                   "Create",
  //                                   style: TextStyle(
  //                                     color: greet,
  //                                     fontSize: 15.0,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                           )
  //                         ],
  //                       )
  //                     ],
  //                   ),
  //                 );
  //               });
  //         },
  //       )));

  //   childButtons.add(UnicornButton(
  //       labelText: "Chat with a person",
  //       hasLabel: true,
  //       currentButton: FloatingActionButton(
  //           heroTag: "plane",
  //           backgroundColor: Colors.blue,
  //           mini: true,
  //           onPressed: () {
  //             showSearch(
  //                 context: context,
  //                 delegate: UserSearch(widget.username, greet, background));
  //           },
  //           child: Icon(Icons.person))));

  //   childButtons.add(UnicornButton(
  //       labelText: "Flip theme",
  //       hasLabel: true,
  //       currentButton: FloatingActionButton(
  //           heroTag: "planex",
  //           backgroundColor: Colors.greenAccent,
  //           mini: true,
  //           onPressed: () {
  //             darkTheme();
  //           },
  //           child: Icon(Icons.flip_to_front))));
  // }
  //PageController controller = PageController();
  List<GButton> tabs = new List();
  List<Color> colors = [
    Colors.purple,
    Colors.pink,
    Colors.amber[600],
    Colors.teal
  ];

  _addNavBarButtons() {
    var padding = EdgeInsets.symmetric(horizontal: 12, vertical: 5);
    double gap = 30;

    tabs.add(GButton(
      gap: gap,
      iconActiveColor: Colors.purple,
      iconColor: Colors.grey,
      textColor: Colors.purple,
      color: Colors.purple.withOpacity(.2),
      iconSize: 24,
      padding: padding,
      icon: LineIcons.home,
      // textStyle: t.textStyle,
      text: 'Home',
    ));

    tabs.add(GButton(
      gap: gap,
      iconActiveColor: Colors.pink,
      iconColor: Colors.grey,
      textColor: Colors.pink,
      color: Colors.pink.withOpacity(.2),
      iconSize: 24,
      padding: padding,
      icon: LineIcons.heart_o,
      // textStyle: t.textStyle,
      text: 'Likes',
    ));

    tabs.add(GButton(
      gap: gap,
      iconActiveColor: Colors.amber[600],
      iconColor: Colors.grey,
      textColor: Colors.amber[600],
      color: Colors.amber[600].withOpacity(.2),
      iconSize: 24,
      padding: padding,
      icon: LineIcons.search,
      // textStyle: t.textStyle,
      text: 'Search',
    ));

    tabs.add(GButton(
      gap: gap,
      iconActiveColor: Colors.teal,
      iconColor: Colors.grey,
      textColor: Colors.teal,
      color: Colors.teal.withOpacity(.2),
      iconSize: 24,
      padding: padding,
      icon: LineIcons.user,
      // textStyle: t.textStyle,
      text: 'Profile',
    ));
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      body: IndexedStack(
        index: selectedIndex,
        children: <Widget>[
          _buildBody(0),
          _buildBody(0),
          Container(),
          Profile(
            username: widget.username,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: background,
            //borderRadius: BorderRadius.all(Radius.circular(100)),
            boxShadow: [
              BoxShadow(
                  spreadRadius: -10,
                  blurRadius: 60,
                  color: Colors.black.withOpacity(.20),
                  offset: Offset(0, 15))
            ]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5),
          child: GNav(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onTabChange: (index) {
                print(index);
                setState(() {
                  selectedIndex = index;
                });
              }),
        ),
      ),
      // floatingActionButton: UnicornDialer(
      //   childButtons: childButtons,
      //   backgroundColor: Colors.transparent,
      //   parentButtonBackground: Color(0xFF27E9E1),
      //   parentButton: Icon(Icons.add),
      //   orientation: UnicornOrientation.VERTICAL,
      // ),
      appBar: new AppBar(
        backgroundColor: background,
        centerTitle: true,
        title: Text(
          "Talking Pigeon",
          style: TextStyle(color: greet, fontSize: 28.0),
        ),
        elevation: 0.0,
        actions: <Widget>[
          new PopupMenuButton<String>(
            onSelected: menuList,
            color: background,
            icon: new Icon(
              Icons.more_vert,
              color: Color(0xFF27E9E1),
              size: 30.0,
            ),
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              PopupMenuItem<String>(
                value: 'a',
                child: ListTile(
                  leading: Icon(Icons.edit,
                      color: background == Color(0xff242424)
                          ? Colors.white
                          : Colors.black),
                  title: Text(
                    "$theme",
                    style: TextStyle(
                      color: background == Color(0xff242424)
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'b',
                child: ListTile(
                  leading: Icon(
                    Icons.cancel,
                  ),
                  title: Text("Sign Out"),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'c',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text("Exit"),
                ),
              ),
            ],
          ),
        ],
        // actions: <Widget>[
        //   new IconButton(
        //     icon: new Icon(
        //       Icons.search,
        //       size: 30.0,
        //     ),
        //     onPressed: () {
        //       showSearch(
        //           context: context,
        //           delegate: UserSearch(widget.username, greet, background));
        //     },
        //     color: Color(0xFF27E9E1),
        //   ),
        //   Padding(
        //     padding: EdgeInsets.only(right: 5.0),
        //   ),
        // ],
      ),
    );
  }
}
