import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:talking_pigeon_x/Pages/ChatPage/friendsprofile.dart';
import 'package:talking_pigeon_x/Pages/Global/commonid.dart';
import 'package:talking_pigeon_x/Pages/Global/timestamp.dart';
import 'package:talking_pigeon_x/Pages/widgets/bubble.dart';
//Used in case when the image needs to be uploaded to imgbb.

class ChatPage extends StatefulWidget {
  final Color greet;
  final Color background;
  final String name;
  final String frienduid;

  ChatPage({Key key, this.name, this.greet, this.background, this.frienduid})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int selectedIndex = 0;
  Stream<QuerySnapshot> snap;
  StreamSubscription snapshotlastseen;
  DocumentSnapshot lastDocument;
  List listMsg = [];
  String msg;
  String name;
  List<String> receiverToken = [];
  String status = "";
  String imageUrl = "";
  String statusForEveryone = "";
  final CommonID commonID = CommonID();
  final ScrollController listScrollController = new ScrollController();
  final TextEditingController textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final TimeStamp _timeStamp = TimeStamp();

  @override
  void initState() {
    super.initState();
    textEditingController.clear();
    listScrollController.addListener(() {
      double maxscroll = listScrollController.position.maxScrollExtent;
      double currentscroll = listScrollController.position.pixels;
      double delta = MediaQuery.of(context).size.height * 0.20;
      if (maxscroll - currentscroll <= delta) {
        setState(() {});
      }
    });
    setState(() {
      snap = snapshotReturn();
      snapshotlastseen = _fetchInitDetails().listen((val) {
        DocumentSnapshot db = val.documents[0];
        setState(() {
          status = db["status"] ?? " ";
          receiverToken.add(db["deviceId"]);
          imageUrl = db["thumbnail"];
          statusForEveryone = db["status_for_everyone"];
          name = db["name"] ?? "";
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    textEditingController.dispose();
    snapshotlastseen.cancel();
  }

  Stream<QuerySnapshot> _fetchInitDetails() {
    Stream<QuerySnapshot> snap = Firestore.instance
        .collection("Users")
        .where("username", isEqualTo: "${widget.frienduid}")
        .snapshots();
    return snap;
  }

  Stream<QuerySnapshot> snapshotReturn() {
    final String groupId =
        commonID.singleChatConversationID(widget.name, widget.frienduid);
    Stream<QuerySnapshot> snap = Firestore.instance
        .collection('messages')
        .document(groupId)
        .collection(groupId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
    return snap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        elevation: 0.0,
        automaticallyImplyLeading: false,
        titleSpacing: 0.0,
        backgroundColor: Theme.of(context).appBarTheme.color,
        title: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(30.0),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  margin: const EdgeInsets.all(3.0),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 5.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: new CircleAvatar(
                          radius: 20.0,
                          backgroundColor: Theme.of(context).backgroundColor,
                          foregroundColor: Theme.of(context).primaryColor,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: imageUrl ??
                                  "https://i.ya-webdesign.com/images/default-image-png-1.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => UserProfile(
                          username: widget.frienduid,
                          imageUrl: imageUrl,
                          lastseen: status,
                          statusForEveryone: statusForEveryone,
                          name: name,
                          //status is the timestamp and statusforeveryone is the user's showoff msg.
                        )));
              },
              child: Container(
                width: MediaQuery.of(context).size.width - 100.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text(
                      "${widget.frienduid}"
                          .toString()
                          .split(" ")[0], //Change Name to Friends name.
                      style: TextStyle(
                          fontSize: 25.0,
                          color: widget.greet,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _timeStamp.lastSeen(status),
                      style: TextStyle(
                          color: Theme.of(context).textTheme.title.color,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: new Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Flexible(
              child: StreamBuilder(
                  stream: snap,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return SizedBox.expand();
                    else {
                      List<DocumentSnapshot> document =
                          snapshot.data.documents ?? [];
                      return ListView.builder(
                          reverse: true,
                          itemCount: document.length,
                          controller: listScrollController,
                          itemBuilder: (context, i) {
                            if (document.length == 1 ||
                                i == document.length - 1) {
                              return buildColumnWithTime(document[i]);
                            } else {
                              if (i >= 0 &&
                                  _timeStamp.checkChangeInDate(
                                    int.parse(document[i]["timestamp"]),
                                    int.parse(document[i + 1]["timestamp"]),
                                  )) {
                                return buildColumnWithTime(document[i]);
                              }
                              return buildColumn(document[i]);
                            }
                          });
                    }
                  }),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 45.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => sendMessage(
                            textEditingController.value.text,
                            1,
                            ImageSource.gallery,
                          ),
                          icon: Icon(
                            Icons.image,
                            color: Theme.of(context).textTheme.title.color,
                          ),
                        ),
                        IconButton(
                          onPressed: () => sendMessage(
                              textEditingController.value.text,
                              1,
                              ImageSource.camera),
                          icon: Icon(
                            Icons.camera,
                            color: Theme.of(context).textTheme.title.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 5.0,
                  ),
                  Expanded(
                    child: Container(
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
                        focusNode: _focusNode,
                        decoration: new InputDecoration(
                          filled: true,
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                          hintText: "Type a message",
                          hintStyle: TextStyle(
                            fontSize: 15.0,
                            color: Theme.of(context).textTheme.subtitle.color,
                          ),
                          suffixIcon: IconButton(
                            color: Theme.of(context).iconTheme.color,
                            icon: Icon(
                              Icons.send,
                              size: 25.0,
                            ),
                            disabledColor: Colors.grey,
                            onPressed: () =>
                                textEditingController.value.text != ""
                                    ? sendMessage(
                                        textEditingController.value.text,
                                        0,
                                        ImageSource.gallery)
                                    : null,
                          ),
                        ),
                        controller: textEditingController,
                        keyboardType: TextInputType.text,
                        enableSuggestions: true,
                        autocorrect: true,
                        style: TextStyle(
                            color: Theme.of(context).textTheme.title.color),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Column buildColumn(DocumentSnapshot document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Bubble(
          message: document["content"],
          notMe: document["isMe"].compareTo(widget.name) == 0 ? false : true,
          delivered: true,
          sendername: document["isMe"],
          timestamp: document["timestamp"],
          methodVia: 0,
          background: widget.background,
          type: document["isImage"] == true ? 1 : 0,
        ),
      ],
    );
  }

  Column buildColumnWithTime(DocumentSnapshot document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).textTheme.title.color, width: 0.5),
                borderRadius: BorderRadius.circular(20.0)),
            child: Text(
              DateFormat("MMM dd, y").format(
                DateTime.fromMillisecondsSinceEpoch(
                  int.parse(document["timestamp"]),
                ),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.title.color),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Bubble(
          message: document["content"],
          notMe: document["isMe"].compareTo(widget.name) == 0 ? false : true,
          delivered: true,
          sendername: document["isMe"],
          timestamp: document["timestamp"],
          methodVia: 0,
          background: widget.background,
          type: document["isImage"] == true ? 1 : 0,
        ),
      ],
    );
  }

  void sendMessage(String content, int type, ImageSource source) async {
    //message type = 0; image type = 1;
    //Camera option: 0; gallery option: 1
    final int timeStamp = DateTime.now().millisecondsSinceEpoch;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => textEditingController.clear());
    String imageUrl;
    var url;
    if (type == 1) {
      File _image = await ImagePicker.pickImage(source: source, maxWidth: 1024);
      _image = await ImageCropper.cropImage(
        sourcePath: _image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio5x4,
          CropAspectRatioPreset.ratio7x5,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ],
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: '',
          backgroundColor: Theme.of(context).backgroundColor,
          showCropGrid: false,
          activeControlsWidgetColor: Theme.of(context).primaryColor,
          //If theme color is added then change this, otherwise the theme of the app.
          toolbarColor: Theme.of(context).backgroundColor,
          toolbarWidgetColor: Theme.of(context).iconTheme.color,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      );
      List<int> imageBytes = _image.readAsBytesSync();
      imageUrl = base64Encode(imageBytes);
      // print(imageUrl); Very bad algortihm, try not to use.
      Map<String, dynamic> body = {
        "key": "400b0402ee29bc7eb67b70b35f836fcd",
        "image": imageUrl,
      };
      try {
        var response =
            await http.post("https://api.imgbb.com/1/upload", body: body);
        var jsonObject = json.decode(response.body);
        url = jsonObject["data"]["url"];
      } catch (e) {
        throw e;
      }
    } else if (type == 0) {
      setState(() {
        listScrollController.animateTo(0.0,
            duration: Duration(milliseconds: 300), curve: Curves.elasticIn);
        //Refreshing widget when new message is sent or appears.
      });
    }
    //Compulsory transaction.
    Map<String, dynamic> transaction = {
      'timestamp': timeStamp.toString(),
      'content': type == 0 ? content : url,
      //add url later to this part of the image that is uploaded either on imgbb or firebase storage.
      'isMe': widget.name,
      'isImage': type == 1,
      'groupchat': "false",
      'groupid': "",
      'groupname': "",
      'receiverToken': receiverToken
      //this set isImage field to boolean true if it is an image else false if it is a message.
    };

    await Firestore.instance
        .collection('messages')
        .document(
            commonID.singleChatConversationID(widget.name, widget.frienduid))
        .collection(
            commonID.singleChatConversationID(widget.name, widget.frienduid))
        .document(timeStamp.toString())
        .setData(transaction);
    //Updating latest timestamp on sender's friendlist
    await Firestore.instance
        .collection("FriendList")
        .document("FriendList")
        .collection(widget.name)
        .document(widget.frienduid)
        .updateData({"lastTimestamp": timeStamp.toString()});
    //Updating latest timestamp on receiver's friendlist
    await Firestore.instance
        .collection("FriendList")
        .document("FriendList")
        .collection(widget.frienduid)
        .document(widget.name)
        .updateData({"lastTimestamp": timeStamp.toString()});
  }
}
