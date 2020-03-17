import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talking_pigeon_x/Pages/Global/commonid.dart';
import 'package:http/http.dart' as http;

class CreateGroup extends StatefulWidget {
  final String username;
  final String deviceId;

  const CreateGroup({
    Key key,
    this.username,
    @required this.deviceId,
  }) : super(key: key);
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  Stream<QuerySnapshot> streamOfFriends;
  CommonID commonID = CommonID();
  TextEditingController controllerGroupName = TextEditingController();
  String imageUrl = "";
  Color groupNameColor = Colors.red;
  Color groupPicColor = Colors.red;
  Map<String, String> selectedFriendsRegistrationToken = {};
  List<String> selectedFriends = [];
  @override
  void initState() {
    selectedFriendsRegistrationToken[widget.username] = widget.deviceId;
    streamOfFriends = _fetchFromFriendsCollection();
    controllerGroupName.addListener(() {
      setState(() {
        groupNameColor = controllerGroupName.text == ""
            ? Colors.red
            : Theme.of(context).textTheme.title.color;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    controllerGroupName.dispose();
    super.dispose();
  }

  Future<void> createGroup(String username, List<String> members,
      String groupName, String imageUrl, List<String> memberTokens) async {
    String uniqueGroupID = commonID.groupChatConversationID(username);
    DocumentReference reference =
        Firestore.instance.document("messages/$uniqueGroupID");
    await Firestore.instance
        .collection("Groups")
        .document(uniqueGroupID)
        .setData({
      "members": members,
      "conversations": reference,
      "groupname": groupName,
      "admin": username,
      "imageUrl": imageUrl,
      "groupid": uniqueGroupID,
      "deviceId": memberTokens
    });
  }

  Stream<QuerySnapshot> _fetchFromFriendsCollection() {
    return Firestore.instance
        .collection("FriendList")
        .document("FriendList")
        .collection(widget.username)
        .orderBy("lastTimestamp", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _friendInfo(String friend) {
    return Firestore.instance
        .collection("Users")
        .where('username', isEqualTo: friend)
        .snapshots();
  }

  void uploadProfilePic() async {
    File _image = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024);
    if (_image != null) {
      String profileImageUrl;
      List<int> imageBytes = _image.readAsBytesSync();
      profileImageUrl = base64Encode(imageBytes);
      // print(imageUrl); Very bad algortihm, try not to use.
      Map<String, dynamic> body = {
        "key": "400b0402ee29bc7eb67b70b35f836fcd",
        "image": profileImageUrl,
      };
      try {
        var response =
            await http.post("https://api.imgbb.com/1/upload", body: body);
        var jsonObject = json.decode(response.body);
        setState(() {
          imageUrl = jsonObject["data"]["thumb"]["url"];
          groupPicColor = Theme.of(context).textTheme.title.color;
        });
      } catch (e) {
        throw e;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(
          Icons.arrow_forward,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () {
          if (controllerGroupName.text != "" &&
              selectedFriendsRegistrationToken.length >= 3) {
            List<String> memberTokens = [];
            for (String i in selectedFriendsRegistrationToken.keys) {
              memberTokens.add(selectedFriendsRegistrationToken[i]);
            }
            createGroup(
              widget.username,
              selectedFriendsRegistrationToken.keys.toList(),
              controllerGroupName.text,
              imageUrl,
              memberTokens,
            );
            print(memberTokens);
            Navigator.of(context).pop();
          }
        },
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Create group",
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500),
        ),
        elevation: 0.0,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ),
      body: SafeArea(
        child: Container(
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Text(
                  "Group Picture",
                  style: TextStyle(
                    color: groupPicColor,
                    fontSize: 25.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 100.0,
                  height: 100.0,
                  margin: const EdgeInsets.only(top: 10.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 1.0,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  child: InkWell(
                    splashColor: Color(0xFF27E9E1),
                    borderRadius: BorderRadius.circular(100.0),
                    onTap: uploadProfilePic,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl != ""
                            ? imageUrl
                            : "https://i.ya-webdesign.com/images/default-image-png-1.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 20.0),
                child: Text(
                  "Group Name",
                  style: TextStyle(
                    color: groupNameColor,
                    fontSize: 25.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  left: 25.0,
                  right: 25,
                  top: 20.0,
                  bottom: 20.0,
                ),
                height: 45.0,
                //width: MediaQuery.of(context).size.width * 0.75,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: new BorderRadius.circular(50.0),
                  border: Border.all(
                    color: Theme.of(context).canvasColor,
                  ),
                ),
                child: TextFormField(
                  textAlign: TextAlign.start,
                  decoration: new InputDecoration(
                    filled: true,
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    hintText: "Enter group name",
                    hintStyle: TextStyle(
                      fontSize: 15.0,
                      color: Colors.grey,
                    ),
                  ),
                  controller: controllerGroupName,
                  keyboardType: TextInputType.text,
                  enableSuggestions: true,
                  autocorrect: true,
                  style:
                      TextStyle(color: Theme.of(context).textTheme.title.color),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25, bottom: 10.0),
                child: Text(
                    "Select Members (" +
                        (selectedFriendsRegistrationToken.length - 1)
                            .toString() +
                        ")",
                    style: TextStyle(
                      color: selectedFriendsRegistrationToken.length < 3
                          ? Colors.red
                          : Theme.of(context).textTheme.title.color,
                      fontSize: 25.0,
                      fontWeight: FontWeight.w500,
                    )),
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
                                  String friendUsername =
                                      snap.data.documents[index]["username"];
                                  return StreamBuilder<QuerySnapshot>(
                                      stream: _friendInfo(friendUsername),
                                      builder: (context, snapshot) {
                                        return !snapshot.hasData
                                            ? Container()
                                            : GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedFriendsRegistrationToken
                                                            .containsKey(
                                                                friendUsername)
                                                        ? selectedFriendsRegistrationToken
                                                            .remove(
                                                                friendUsername)
                                                        : selectedFriendsRegistrationToken[
                                                                friendUsername] =
                                                            snapshot.data
                                                                    .documents[
                                                                0]['deviceId'];
                                                  });
                                                  print(
                                                      selectedFriendsRegistrationToken);
                                                },
                                                child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.only(
                                                      left: 20.0,
                                                      top: 0.0,
                                                      right: 20.0,
                                                    ),
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
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 5.0),
                                                        child: Text(
                                                          snapshot.data.documents[
                                                                      0][
                                                                  "status_for_everyone"] ??
                                                              "I am using Talking Pigeon",
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12.0,
                                                          ),
                                                        )),
                                                    leading: Container(
                                                      height: 50.0,
                                                      width: 50.0,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Stack(
                                                        children: <Widget>[
                                                          CircleAvatar(
                                                            radius: 27.0,
                                                            backgroundColor: Theme
                                                                    .of(context)
                                                                .backgroundColor,
                                                            foregroundColor:
                                                                Theme.of(
                                                                        context)
                                                                    .primaryColor,
                                                            child: ClipOval(
                                                              child:
                                                                  CachedNetworkImage(
                                                                imageUrl: snapshot
                                                                            .data
                                                                            .documents[0]
                                                                        [
                                                                        "thumbnail"] ??
                                                                    "https://i.ya-webdesign.com/images/default-image-png-1.png",
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                          ),
                                                          selectedFriendsRegistrationToken
                                                                  .containsKey(
                                                                      friendUsername)
                                                              ? Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .bottomRight,
                                                                  child:
                                                                      Container(
                                                                    height: 20,
                                                                    width: 20,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .primaryColor,
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .check,
                                                                      color: Colors
                                                                          .white,
                                                                      size:
                                                                          15.0,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Container(),
                                                        ],
                                                      ),
                                                    )),
                                              );
                                      });
                                },
                              );
                      }))
            ],
          ),
        ),
      ),
    );
  }
}
