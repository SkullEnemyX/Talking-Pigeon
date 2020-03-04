import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfile extends StatefulWidget {
  final String username;
  UserProfile({this.username});
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Stream<QuerySnapshot> snapshot;
  TextEditingController _textEditingController = TextEditingController();

  Stream<QuerySnapshot> readUserInfo(String username) {
    return Firestore.instance
        .collection("Users")
        .where("username", isEqualTo: username)
        .snapshots();
  }

  String lastSeen(String status) {
    if (status.compareTo("online") == 0 ||
        status.compareTo(" ") == 0 ||
        status == null) {
      return status;
    } else {
      var now = DateTime.now();
      var date = DateTime.fromMillisecondsSinceEpoch(int.parse(status));
      var diff = now.difference(date);
      var formatHR = DateFormat("hh:mm a");
      var formatDAY = DateFormat("MMM dd, y");
      if (diff.inDays < 1) {
        return "last seen today at " + formatHR.format(date);
      } else if (diff.inDays == 1) {
        return "last seen yesterday at " + formatHR.format(date);
      }
      return "last seen on " + formatDAY.format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    snapshot = readUserInfo(widget.username);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: snapshot,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            DocumentSnapshot documentSnapshot = snapshot.data.documents[0];
            _textEditingController.text =
                documentSnapshot["status_for_everyone"] ??
                    "I am using Talking Pigeon.";
            return Scaffold(
              backgroundColor: Theme.of(context).backgroundColor,
              appBar: AppBar(
                elevation: 0.0,
                backgroundColor: Theme.of(context).appBarTheme.color,
                primary: true,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "${widget.username}"
                          .toString()
                          .split(" ")[0], //Change Name to Friends name.
                      style: TextStyle(
                        fontSize: 25.0,
                        color: Theme.of(context).textTheme.title.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      lastSeen(documentSnapshot["status"]),
                      style: TextStyle(
                          color: Theme.of(context).textTheme.title.color,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                leading: new IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF27E9E1),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Container(
                        width: 200.0,
                        height: 200.0,
                        margin: const EdgeInsets.only(top: 10.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: InkWell(
                          splashColor: Color(0xFF27E9E1),
                          borderRadius: BorderRadius.circular(100.0),
                          onTap: () {},
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: documentSnapshot["thumbnail"] ??
                                  "https://i.ya-webdesign.com/images/default-image-png-1.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        "@" + widget.username,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.title.color,
                          fontSize: 25.0,
                        ),
                      ),
                      SizedBox(
                        height: 1.0,
                      ),
                      Text(
                        documentSnapshot["name"],
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15.0,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 30.0, left: 30.0, bottom: 2.0),
                          child: Text(
                            "Status",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.title.color,
                              fontSize: 25.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 15.0,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Theme.of(context).backgroundColor !=
                                      Color(0xff242424)
                                  ? Border.all(
                                      color: Colors.grey.shade200,
                                    )
                                  : null,
                              boxShadow: Theme.of(context).backgroundColor !=
                                      Color(0xff242424)
                                  ? [
                                      BoxShadow(
                                        blurRadius: 2.0,
                                        spreadRadius: 1.0,
                                        color: Colors.grey.shade100,
                                      )
                                    ]
                                  : null,
                            ),
                            padding:
                                const EdgeInsets.only(left: 20.0, right: 5.0),
                            child: TextField(
                              readOnly: true,
                              textAlign: TextAlign.start,
                              textAlignVertical: TextAlignVertical.center,
                              controller: _textEditingController,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.title.color,
                                fontSize: 18.0,
                              ),
                              maxLines: 2,
                              maxLength: 100,
                              expands: true,
                              enableSuggestions: true,
                              decoration: InputDecoration(
                                counter: Container(),
                                border: InputBorder.none,
                              ),
                              autofocus: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(child: SizedBox()),
                ],
              ),
            );
          } else {
            return Container();
          }
        });
  }
}
