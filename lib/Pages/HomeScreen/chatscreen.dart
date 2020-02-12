import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:talking_pigeon_x/Pages/Authentication/authentication.dart';
import 'package:talking_pigeon_x/Pages/Authentication/sign-in.dart';
import 'package:talking_pigeon_x/Pages/ChatPage/chatpage.dart';
import 'package:talking_pigeon_x/Pages/Group/groupchat.dart';
import 'package:talking_pigeon_x/Pages/HomeScreen/usersearch.dart';
import 'package:talking_pigeon_x/Pages/Profile/profile.dart';
import 'package:talking_pigeon_x/widget/animated_bottombar.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var globalUsername;
Color greet;
Color background;

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
  String name;
  String theme = "Dark Theme";
  int gvalue = 0;
  TextEditingController textEditingController = TextEditingController();
  int hour;
  int selectedBarIndex = 0;
  Userauthentication userAuth = new Userauthentication();
  UserData userData = new UserData();
  //bool loadingInProgress;
  String lastMessage;
  String friendid;
  var childButtons = List<UnicornButton>();
  //Bottom Animated Bar
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
  //Ends here.

  @override
  void initState() {
    super.initState();
    //getSharedPrefs();
    _initx();
    insertUnicornButtons();
  }

  _initx() {
    fetchTime();
    darkTheme();
    //friendfunc();
  }

  // Future<Null> getSharedPrefs() async {
  //   //loadingInProgress = true;
  //   final DocumentReference documentReference =
  //       Firestore.instance.document("Users/${widget.username}");
  //   globalUsername = "${widget.username}";
  //   await documentReference.get().then((snapshot) {
  //     if (snapshot.exists) {
  //       setState(() {
  //         name = snapshot.data['name'];
  //       });
  //     }
  //   });
  // }

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
    var format = new DateFormat('HH:mm a');
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

  Stream<QuerySnapshot> fetchMessages(List<dynamic> finalList) {
    String insertVal = finalList[0];
    if (finalList[1] == 0) {
      Stream<QuerySnapshot> snap = Firestore.instance
          .collection('messages')
          .document(returnGroupId(globalUsername, insertVal))
          .collection(returnGroupId(globalUsername, insertVal))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots();
      return snap;
    } else {
      Stream<QuerySnapshot> snap = Firestore.instance
          .collection('messages')
          .document(insertVal)
          .collection(insertVal)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots();
      return snap;
    }
  }

  fetchData() {
    Stream<QuerySnapshot> snapshot = Firestore.instance
        .collection("Users")
        .where('username', isEqualTo: widget.username)
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
              child: StreamBuilder(
                  stream: fetchData(),
                  builder: (context, snap) {
                    List list;
                    List friends = [];
                    if (snap.hasData) {
                      List<DocumentSnapshot> docs = snap.data.documents;
                      //print(docs.length);
                      list = docs[0]["friends"];
                      //print(list);
                      for (int i = 0; i < list.length; i++) {
                        friends.add(list[i].keys.toList()[0]);
                      }
                      //print(friends);
                    }

                    return friends.length < 1
                        ? Center(
                            child: Text(
                              selection == 0
                                  ? "Add new friends to start the conversation"
                                  : "Make new group and add people",
                              style: TextStyle(
                                color: greet,
                              ),
                            ),
                          )
                        : snap.hasData
                            ? ListView.builder(
                                itemCount: list?.length ?? 0,
                                itemBuilder: (context, index) {
                                  DocumentReference ref =
                                      list[index][friends[index]];
                                  return StreamBuilder(
                                      stream: friendFetchQuerySnapshot(
                                          returnGroupId(
                                              widget.username, friends[index]),
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
                                                            name:
                                                                widget.username,
                                                            frienduid:
                                                                friends[index],
                                                            greet: greet,
                                                            background:
                                                                background,
                                                          )));
                                            },
                                            title: Text(
                                              friends[index],
                                              style: TextStyle(
                                                  color: greet,
                                                  fontSize: 20.0,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Container(
                                                padding:
                                                    EdgeInsets.only(top: 5.0),
                                                child: formatLastMessage(
                                                    documents[0]["content"],
                                                    TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 15.0,
                                                    ),
                                                    greet)),
                                            trailing: snapshot
                                                    .data.documents.isEmpty
                                                ? Text(" ")
                                                : Text(
                                                    customTimestamp(int.parse(
                                                        documents[0]
                                                                ["timestamp"]
                                                            .toString())),
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
                                                foregroundColor:
                                                    Color(0xFF27E9E1),
                                                child: Text(
                                                  fetchInitials(friends[index]),
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20.0),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return Container();
                                      });
                                },
                              )
                            : Container();
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
      userAuth.logout(userData);
      prefs.setString('username', '');
      prefs.setString('password', '');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } else if (value == 'c') {
      exit(0);
    }
  }

  insertUnicornButtons() {
    childButtons.add(UnicornButton(
        hasLabel: true,
        labelText: "Create a team",
        currentButton: FloatingActionButton(
          heroTag: "train",
          backgroundColor: Colors.redAccent,
          mini: true,
          child: Icon(Icons.group),
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("What is your team called?"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          controller: textEditingController,
                          autofocus: true,
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  textEditingController.clear();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 12.0),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius:
                                          BorderRadius.circular(12.0)),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: greet,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  String groupId = DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString();
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (context) => GroupChat(
                                                groupName: textEditingController
                                                    .value.text,
                                                admin: globalUsername,
                                                greet: greet,
                                                groupId: groupId,
                                                background: background,
                                                username: globalUsername,
                                              )))
                                      .whenComplete(() {
                                    textEditingController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 12.0),
                                  decoration: BoxDecoration(
                                      color: Color(0xFF27E9E1),
                                      borderRadius:
                                          BorderRadius.circular(12.0)),
                                  child: Text(
                                    "Create",
                                    style: TextStyle(
                                      color: greet,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                });
          },
        )));

    childButtons.add(UnicornButton(
        labelText: "Chat with a person",
        hasLabel: true,
        currentButton: FloatingActionButton(
            heroTag: "plane",
            backgroundColor: Colors.blue,
            mini: true,
            onPressed: () {
              showSearch(
                  context: context,
                  delegate: UserSearch(widget.username, greet, background));
            },
            child: Icon(Icons.person))));

    childButtons.add(UnicornButton(
        labelText: "Flip theme",
        hasLabel: true,
        currentButton: FloatingActionButton(
            heroTag: "planex",
            backgroundColor: Colors.greenAccent,
            mini: true,
            onPressed: () {
              darkTheme();
            },
            child: Icon(Icons.flip_to_front))));
  }

  showScreen(int index) {
    if (index == 0) {
      return _buildBody(index);
    } else if (selectedBarIndex == 1) {
      return _buildBody(index);
    } else if (selectedBarIndex == 3) {
      return Profile(
        username: widget.username,
        backgroundColor: background,
      );
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: showScreen(selectedBarIndex),
        bottomNavigationBar: AnimatedBottomBar(
          background: background,
          onBarTap: (index) {
            if (index == 2)
              showSearch(
                  context: context,
                  delegate: UserSearch(widget.username, greet, background));
            else
              setState(() {
                selectedBarIndex = index;
              });
          },
          barItems: barItems,
          animationDuration: const Duration(milliseconds: 150),
          barStyle: BarStyle(fontSize: 15.0, iconSize: 30.0),
        ),
        floatingActionButton: UnicornDialer(
          childButtons: childButtons,
          backgroundColor: Colors.transparent,
          parentButtonBackground: Color(0xFF27E9E1),
          parentButton: Icon(Icons.add),
          orientation: UnicornOrientation.VERTICAL,
        ),
        appBar: new AppBar(
          backgroundColor: background,
          centerTitle: true,
          title: Text(
            "Talking Pigeon",
            style: TextStyle(
              color: greet,
              fontSize: 25.0,
            ),
          ),
          leading: new PopupMenuButton<String>(
            onSelected: menuList,
            icon: new Icon(
              Icons.menu,
              color: Color(0xFF27E9E1),
              size: 30.0,
            ),
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              PopupMenuItem<String>(
                value: 'a',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text("$theme"),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'b',
                child: ListTile(
                  leading: Icon(Icons.cancel),
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
          elevation: 0.0,
          actions: <Widget>[
            new IconButton(
              icon: new Icon(
                Icons.search,
                size: 30.0,
              ),
              onPressed: () {
                showSearch(
                    context: context,
                    delegate: UserSearch(widget.username, greet, background));
              },
              color: Color(0xFF27E9E1),
            ),
            Padding(
              padding: EdgeInsets.only(right: 5.0),
            ),
          ],
        ),
      ),
    );
  }
}

// class UserSearch extends SearchDelegate<String> {
//   //final DocumentReference documentReference = Firestore.instance.document("Users/$globalUsername");
//   final CollectionReference collectionReference =
//       Firestore.instance.collection("Users");
//   List<String> userList = ["null"];
//   List<String> presentList = ["null"];
//   List<String> friendSuggestion = [];
//   var friends;
//   var users;

//   Future<List<String>> addfriends(String username) async {
//     final DocumentReference documentReference =
//         Firestore.instance.document("Users/$username");

//     await documentReference.get().then((snapshot) {
//       if (snapshot.exists) {
//         friends = snapshot.data['friends'];
//       } else {
//         friendSuggestion = [];
//       }
//     });
//     if (friendSuggestion.isNotEmpty) {
//       friendSuggestion.clear();
//       for (int i = 0; i < friends.length; i++) {
//         friendSuggestion.add(friends[i].toString());
//       }
//     }
//     return friendSuggestion;
//   }

//   Future<List<String>> testfunc() async {
//     final DocumentReference documentReference =
//         Firestore.instance.document("Users/$globalUsername");

//     await documentReference.get().then((snapshot) {
//       if (snapshot.exists) {
//         friends = snapshot.data['friends'];
//       }
//     });
//     if (friendSuggestion.isNotEmpty) friendSuggestion.clear();
//     for (int i = 0; i < friends.length; i++) {
//       friendSuggestion.add(friends[i].toString());
//     }
//     return friendSuggestion;
//   }

//   Future<List<String>> checkpart2(String s) async {
//     DocumentReference reference = Firestore.instance.document("People/People");
//     await reference.get().then((snapshot) {
//       if (snapshot.exists) {
//         users = snapshot.data["People"];
//       }
//       if (userList.isNotEmpty) userList.clear();
//       for (int i = 0; i < users.length; i++) {
//         userList.add(users[i].toString());
//       }
//       userList.remove(globalUsername);
//     });
//     //print(userList.where((p)=>p.startsWith(s)).toList()); Used in case we want to return query beginning
//     return userList
//         .where((p) => p.startsWith(s))
//         .toList(); //If exact match needed on query.
//   }

//   @override
//   List<Widget> buildActions(BuildContext context) {
//     return [
//       IconButton(
//         icon: Icon(Icons.clear),
//         onPressed: () {},
//       )
//     ];
//   }

//   @override
//   Widget buildLeading(BuildContext context) {
//     return IconButton(
//       icon: AnimatedIcon(
//         icon: AnimatedIcons.menu_arrow,
//         progress: transitionAnimation,
//       ),
//       onPressed: () {
//         close(context, null);
//       },
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     return FutureBuilder(
//         future: checkpart2(query),
//         builder: (BuildContext context, AsyncSnapshot snapshot) {
//           if (snapshot.connectionState ==
//               ConnectionState.done) if (snapshot.data.length < 1)
//             return Container(
//               child: Center(
//                 child: Text("No user found"),
//               ),
//             );
//           else
//             return ListView.builder(
//               itemCount: snapshot.data.length,
//               itemBuilder: (context, index) {
//                 print(snapshot.data.length);
//                 return InkWell(
//                   splashColor: Color(0xFF27E9E1),
//                   onTap: () async {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => ChatPage(
//                                   name: globalUsername,
//                                   greet: greet,
//                                   background: background,
//                                   frienduid: snapshot.data[index],
//                                 )));
//                     //Adding people to each other's friendlist if one selects the name of the user.
//                     var list = await addfriends(globalUsername);
//                     if (!list.contains(snapshot.data[index])) {
//                       list.add(snapshot.data[index].toString());
//                       DocumentReference ref =
//                           Firestore.instance.document("Users/$globalUsername");
//                       Map<String, dynamic> peopledata = <String, dynamic>{
//                         "friends": list,
//                       };
//                       await ref.updateData(peopledata).whenComplete(() {
//                         list = [];
//                       }).catchError((e) => print(e));
//                     }
//                     list = await addfriends(snapshot.data[index]);
//                     if (!list.contains(globalUsername)) {
//                       list.add(globalUsername);
//                       DocumentReference ref = Firestore.instance
//                           .document("Users/${snapshot.data[index]}");
//                       Map<String, dynamic> peopledata = <String, dynamic>{
//                         "friends": list,
//                       };
//                       await ref
//                           .updateData(peopledata)
//                           .whenComplete(() {})
//                           .catchError((e) => print(e));
//                     }
//                   },
//                   child: Container(
//                     child: Column(
//                       children: <Widget>[
//                         ListTile(
//                           leading: Icon(Icons.person),
//                           title: Text(snapshot.data[index]),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.only(top: 2.0),
//                         ),
//                         Divider(
//                           color: Colors.grey,
//                           height: 2.0,
//                           indent: 70.0,
//                         )
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           else {
//             return Center(
//                 child: SpinKitDoubleBounce(
//               size: 60.0,
//               color: Color(0xFF27E9E1),
//             ));
//           }
//         });
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     // presentList = query.isEmpty?friendSuggestion:userList.where((word)=>word.startsWith(query)).toList();

//     return query.isEmpty
//         ? FutureBuilder(
//             future: testfunc(),
//             builder: (BuildContext context, AsyncSnapshot snapshot) {
//               if (snapshot.connectionState == ConnectionState.done)
//                 return ListView.builder(
//                   itemBuilder: (context, index) => InkWell(
//                     splashColor: Color(0xFF27E9E1),
//                     onTap: () {
//                       Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => ChatPage(
//                                     name: globalUsername,
//                                     greet: greet,
//                                     background: background,
//                                     frienduid: snapshot.data[index],
//                                   )));
//                     },
//                     child: Container(
//                       child: Column(
//                         children: <Widget>[
//                           ListTile(
//                             leading: Icon(Icons.person),
//                             title: Text(snapshot.data[index]),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.only(top: 2.0),
//                           ),
//                           Divider(
//                             color: Colors.grey,
//                             height: 2.0,
//                             indent: 70.0,
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//                   itemCount: snapshot.data?.length ?? 0,
//                 );
//               else {
//                 return Center(
//                     child: SpinKitDoubleBounce(
//                   size: 60.0,
//                   color: Color(0xFF27E9E1),
//                 ));
//               }
//             })
//         : FutureBuilder(
//             future: checkpart2(query),
//             builder: (BuildContext context, AsyncSnapshot snapshot) {
//               if (snapshot.connectionState ==
//                   ConnectionState.done) if (snapshot.data.length < 1)
//                 return Container(
//                   child: Center(
//                     child: Text("No user found"),
//                   ),
//                 );
//               else
//                 return ListView.builder(
//                   itemCount: snapshot.data.length,
//                   itemBuilder: (context, index) {
//                     print(snapshot.data.length);
//                     return InkWell(
//                       splashColor: Color(0xFF27E9E1),
//                       onTap: () async {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => ChatPage(
//                                       name: globalUsername,
//                                       greet: greet,
//                                       background: background,
//                                       frienduid: snapshot.data[index],
//                                     )));
//                         //Adding people to each other's friendlist if one selects the name of the user.
//                         var list = await addfriends(globalUsername);
//                         if (!list.contains(snapshot.data[index])) {
//                           list.add(snapshot.data[index].toString());
//                           DocumentReference ref = Firestore.instance
//                               .document("Users/$globalUsername");
//                           Map<String, dynamic> peopledata = <String, dynamic>{
//                             "friends": list,
//                           };
//                           await ref.updateData(peopledata).whenComplete(() {
//                             list = [];
//                           }).catchError((e) => print(e));
//                         }
//                         list = await addfriends(snapshot.data[index]);
//                         if (!list.contains(globalUsername)) {
//                           list.add(globalUsername);
//                           DocumentReference ref = Firestore.instance
//                               .document("Users/${snapshot.data[index]}");
//                           Map<String, dynamic> peopledata = <String, dynamic>{
//                             "friends": list,
//                           };
//                           await ref
//                               .updateData(peopledata)
//                               .whenComplete(() {})
//                               .catchError((e) => print(e));
//                         }
//                       },
//                       child: Container(
//                         child: Column(
//                           children: <Widget>[
//                             ListTile(
//                               leading: Icon(Icons.person),
//                               title: Text(snapshot.data[index]),
//                             ),
//                             Padding(
//                               padding: EdgeInsets.only(top: 2.0),
//                             ),
//                             Divider(
//                               color: Colors.grey,
//                               height: 2.0,
//                               indent: 70.0,
//                             )
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               else {
//                 return Center(
//                     child: SpinKitDoubleBounce(
//                   size: 60.0,
//                   color: Color(0xFF27E9E1),
//                 ));
//               }
//             });
//   }
// }
