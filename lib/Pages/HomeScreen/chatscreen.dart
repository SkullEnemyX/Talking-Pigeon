import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:talking_pigeon_x/Pages/Authentication/authentication.dart';
import 'package:talking_pigeon_x/Pages/Authentication/sign-in.dart';
import 'package:talking_pigeon_x/Pages/ChatPage/chatpage.dart';
import 'package:talking_pigeon_x/Pages/Global/commonid.dart';
import 'package:talking_pigeon_x/Pages/Global/timestamp.dart';
import 'package:talking_pigeon_x/Pages/Group/groupchat.dart';
import 'package:talking_pigeon_x/Pages/HomeScreen/usersearch.dart';
import 'package:talking_pigeon_x/Pages/Profile/profile.dart';
import 'package:talking_pigeon_x/Pages/widgets/animated_bottombar.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talking_pigeon_x/Pages/Group/creategroup.dart';

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
  String greeting = "";
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
  List<String> selectedFriends = [];
  Stream<QuerySnapshot> streamOfFriends;
  Stream<QuerySnapshot> streamOfGroups;
  var childButtons = List<UnicornButton>();
  final TimeStamp _timeStamp = TimeStamp();
  final CommonID commonID = CommonID();
  bool createGroupButton = false;

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
    int hour = int.tryParse(DateFormat("hh").format(DateTime.now()));
    greeting = _timeStamp.timeOfTheDay(hour);
    selectedFriends.add(widget.username);
    streamOfFriends = _fetchFromFriendsCollection();

    streamOfGroups = fetchGroupData(widget.username);
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

  fetchData() {
    Stream<QuerySnapshot> snapshot = Firestore.instance
        .collection("Users")
        .where('username', isEqualTo: widget.username)
        .snapshots();
    return snapshot;
  }

  Stream<QuerySnapshot> fetchGroupData(String username) {
    return Firestore.instance
        .collection("Groups")
        .where("members", arrayContains: username)
        .snapshots();
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

  Stream<QuerySnapshot> _friendInfo(String friend) {
    return Firestore.instance
        .collection("Users")
        .where('username', isEqualTo: friend)
        .snapshots();
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
    }
    return Text(
      string,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Widget groupBuildBody() {
    return Container(
      child: Column(
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
                      fontSize: 22.0,
                      color: Theme.of(context).textTheme.title.color,
                    ),
                  ),
                  new Padding(
                    padding: EdgeInsets.only(top: 10.0, left: 30.0),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: streamOfGroups,
              builder: (context, snap) {
                return !snap.hasData || snap.data.documents.length < 1
                    ? Center(
                        child: Text(
                        "Create a group and add friends",
                        style: Theme.of(context).textTheme.title,
                      ))
                    : ListView.builder(
                        itemCount: snap.data.documents?.length ?? 0,
                        itemBuilder: (context, index) {
                          String groupName =
                              snap.data.documents[index]["groupname"] ?? "";
                          String groupImageUrl =
                              snap.data.documents[index]["imageUrl"] ?? "";
                          String groupid =
                              snap.data.documents[index]["groupid"] ?? "";
                          return ListTile(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => GroupChat(
                                              username: widget.username,
                                              groupid: groupid,
                                              groupname: groupName,
                                              imageUrl: groupImageUrl,
                                            )));
                              },
                              contentPadding: const EdgeInsets.only(
                                left: 20.0,
                                top: 0.0,
                                right: 20.0,
                              ),
                              title: Text(
                                groupName,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).textTheme.title.color,
                                  fontSize: 16.0,
                                ),
                              ),
                              leading: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 27.0,
                                  backgroundColor:
                                      Theme.of(context).backgroundColor,
                                  foregroundColor:
                                      Theme.of(context).primaryColor,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: groupImageUrl == "" ||
                                              groupImageUrl == null
                                          ? "https://i.ya-webdesign.com/images/default-image-png-1.png"
                                          : groupImageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ));
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget chatbuildBody() {
    return Container(
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
                      fontSize: 22.0,
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
                                      commonID.singleChatConversationID(
                                          widget.username, friendUsername),
                                      ref),
                                  builder: (BuildContext context,
                                      AsyncSnapshot snapshot) {
                                    if (snapshot.hasData) {
                                      List<DocumentSnapshot> documents =
                                          snapshot.data.documents;
                                      return ListTile(
                                        contentPadding: const EdgeInsets.only(
                                            left: 20.0, top: 0.0, right: 20.0),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatPage(
                                                name: widget.username,
                                                frienduid: friendUsername,
                                              ),
                                            ),
                                          );
                                        },
                                        title: Text(
                                          friendUsername,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .title
                                                .color,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        subtitle: Container(
                                            padding: EdgeInsets.only(top: 5.0),
                                            child: formatLastMessage(
                                              documents.isNotEmpty
                                                  ? documents[0]["content"]
                                                  : "*no new messages*",
                                              TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12.0,
                                              ),
                                            )),
                                        trailing:
                                            snapshot.data.documents.isEmpty
                                                ? Text(" ")
                                                : Text(
                                                    documents.isNotEmpty
                                                        ? _timeStamp
                                                            .lastMessageTimestamp(
                                                                int.parse(
                                                                    documents[0]
                                                                            [
                                                                            "timestamp"] ??
                                                                        ""))
                                                        : "",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12.0,
                                                    ),
                                                  ),
                                        leading: StreamBuilder<QuerySnapshot>(
                                            stream: _friendInfo(snap.data
                                                .documents[index]["username"]),
                                            builder: (context, snapx) {
                                              if (snapx.hasData) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: new CircleAvatar(
                                                    radius: 27.0,
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .backgroundColor,
                                                    foregroundColor:
                                                        Theme.of(context)
                                                            .primaryColor,
                                                    child: ClipOval(
                                                      child: CachedNetworkImage(
                                                        imageUrl: snapx.data
                                                                    .documents[0]
                                                                ["thumbnail"] ??
                                                            "https://i.ya-webdesign.com/images/default-image-png-1.png",
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    width: 2.0,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: new CircleAvatar(
                                                  radius: 30.0,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .backgroundColor,
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .accentColor,
                                                  child: ClipOval(
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          "https://i.ya-webdesign.com/images/default-image-png-1.png",
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
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

  void menuList(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == 'a') {
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

  List<BarItem> barItems(Color color) {
    final List<BarItem> barItems = [
      BarItem(
        text: "Personal",
        iconData: Icons.chat_bubble_outline,
        color: color,
      ),
      BarItem(
        text: "Groups",
        iconData: Icons.people,
        color: color,
      ),
      BarItem(
        text: "Profile",
        iconData: Icons.person_outline,
        color: color,
      )
    ];
    return barItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                createGroupButton ? Icons.arrow_forward : Icons.add,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CreateGroup(
                          username: widget.username,
                        )));
              },
            )
          : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      body: IndexedStack(
        index: selectedIndex,
        children: <Widget>[
          chatbuildBody(),
          groupBuildBody(),
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
        barItems: barItems(Theme.of(context).primaryColor),
        animationDuration: const Duration(milliseconds: 150),
        barStyle: BarStyle(fontSize: 15.0, iconSize: 30.0),
      ),
      appBar: new AppBar(
        centerTitle: true,
        title: Text(
          "Talking Pigeon",
          style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w500),
        ),
        elevation: 0.0,
        leading: selectedIndex == 1 && createGroupButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  setState(() {
                    createGroupButton = !createGroupButton;
                  });
                })
            : null,
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.search,
                size: 30.0,
                color: Theme.of(context).primaryColor,
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
