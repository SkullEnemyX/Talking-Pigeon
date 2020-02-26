import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:talking_pigeon_x/Pages/ChatPage/chatpage.dart';

class UserSearch extends SearchDelegate {
  final String username;
  final Color greet;
  final Color background;
  UserSearch(this.username, this.greet, this.background);
  DocumentReference reference = Firestore.instance.document("People/People");
  //Function to return a common GROUPID, the same function already exists on the chatscreen page.
  returnGroupId(String myid, String friendid) {
    if (myid.hashCode >= friendid.hashCode) {
      return (myid.hashCode.toString() + friendid.hashCode.toString());
    } else {
      return (friendid.hashCode.toString() + myid.hashCode.toString());
    }
  }

  //Function to find users on the "People" document
  friendAddQuerySnapshot(String username, String friend) async {
    //final String groupId = returnGroupId(widget.name, widget.frienduid);
    String returnGroupID = returnGroupId(username, friend);
    DocumentReference messages =
        Firestore.instance.document("messages/$returnGroupID");
    print(returnGroupID);
    //Running the query for the first user.
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await Firestore.instance
        .collection("FriendList")
        .document("FriendList")
        .collection(username)
        .document(friend)
        .setData({
      "username": friend,
      "conversation": messages,
      "lastTimestamp": timestamp
    });
    await Firestore.instance
        .collection("FriendList")
        .document("FriendList")
        .collection(friend)
        .document(username)
        .setData({
      "username": username,
      "conversation": messages,
      "lastTimestamp": timestamp
    });
  }

  fetchFriendList(String username) async {
    DocumentReference friendsReference =
        Firestore.instance.document("Users/$username");
    List friends;
    await friendsReference.get().then((snapshot) {
      if (!snapshot.exists) {
        friends = [];
      } else {
        friends = snapshot.data["friendList"] ?? [];
      }
    });
    return friends;
  }

  //Function to add friends on both person's friendlist.
  //Function to fetch the list of existing users and search for a friend, add as a friend and then take it to the conversation screen.
  fetchPeopleDetails(String username, String search) async {
    List users;
    List finalUserList = [];
    await reference.get().then((snapshot) {
      if (snapshot.exists) {
        users = snapshot.data["People"] ?? [];
      }
    });
    users.forEach((name) =>
        name.compareTo(username) == 0 ? null : finalUserList.add(name));
    return finalUserList.where((p) => p.startsWith(search)).toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
        future: fetchPeopleDetails(username, query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    return InkWell(
                      splashColor: Color(0xFF27E9E1),
                      onTap: () async {
                        friendAddQuerySnapshot(username, snapshot.data[index]);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatPage(
                                      name: username,
                                      greet: greet,
                                      background: background,
                                      frienduid: snapshot.data[index],
                                    )));
                      },
                      child: Container(
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              leading: Icon(Icons.person),
                              title: Text(snapshot.data[index]),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 2.0),
                            ),
                            Divider(
                              color: Colors.grey,
                              height: 2.0,
                              indent: 70.0,
                            )
                          ],
                        ),
                      ),
                    );
                  });
            }
            return Center(
                child: SpinKitDoubleBounce(
              size: 60.0,
              color: Color(0xFF27E9E1),
            ));
          }
          return Center(
              child: SpinKitDoubleBounce(
            size: 60.0,
            color: Color(0xFF27E9E1),
          ));
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
        future: query.isEmpty
            ? fetchFriendList(username)
            : fetchPeopleDetails(username, query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    return InkWell(
                      splashColor: Color(0xFF27E9E1),
                      onTap: () async {
                        friendAddQuerySnapshot(username, snapshot.data[index]);
                        friendAddQuerySnapshot(snapshot.data[index], username);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatPage(
                                      name: username,
                                      greet: greet,
                                      background: background,
                                      frienduid: snapshot.data[index],
                                    )));
                      },
                      child: Container(
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              leading: Icon(Icons.person),
                              title: Text(snapshot.data[index]),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 2.0),
                            ),
                            Divider(
                              color: Colors.grey,
                              height: 2.0,
                              indent: 70.0,
                            )
                          ],
                        ),
                      ),
                    );
                  });
            }
            return Container();
          }
          return Container();
        });
  }
}
