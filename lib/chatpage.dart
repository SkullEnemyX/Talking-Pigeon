import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart'
    as http; //Used in case when the image needs to be uploaded to imgbb.

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
  var snap;

  @override
  void initState() {
    super.initState();
    textEditingController.clear();
    setState(() {
      snap = snapshotReturn();
    });
    fetchDeviceID();
  }

  @override
  void dispose() {
    super.dispose();
    textEditingController.dispose();
  }

  final TextEditingController textEditingController =
      new TextEditingController();
  List listMsg = [];
  String msg;
  String receiverToken;
  final FirebaseMessaging _messaging = FirebaseMessaging();
  final ScrollController listScrollController = new ScrollController();

  fetchDeviceID() async {
    final DocumentReference documentReference =
        Firestore.instance.document("Users/${widget.frienduid}");
    await documentReference.get().then((snapshot) {
      if (snapshot.exists) {
        receiverToken = snapshot.data["deviceId"];
        print(receiverToken);
        _messaging.getToken().then((token) {
          print(token);
        });
      }
    });
  }

  messageList(String msg, bool notme, String timestamp) {
    if (listMsg.length >= 20) {
      listMsg.removeAt(0);
    }
    listMsg.add([msg, notme, timestamp]);
    return listMsg;
  }

  returnGroupId(String myid, String friendid) {
    if (myid.hashCode >= friendid.hashCode) {
      return (myid.hashCode.toString() + friendid.hashCode.toString());
    } else {
      return (friendid.hashCode.toString() + myid.hashCode.toString());
    }
  }

  Stream<QuerySnapshot> snapshotReturn() {
    var snap = Firestore.instance
        .collection('messages')
        .document(returnGroupId(widget.name, widget.frienduid))
        .collection(returnGroupId(widget.name, widget.frienduid))
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
    return snap;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: new AppBar(
          elevation: 0.0,
          backgroundColor: widget.background,
          centerTitle: true,
          title: new Text(
            "${widget.frienduid}"
                .toString()
                .split(" ")[0], //Change Name to Friends name.
            style: TextStyle(fontSize: 23.0, color: widget.greet),
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
        body: new Container(
          color: widget.background,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Flexible(
                child: StreamBuilder(
                    stream: snap,
                    builder: (context, snapshot) {
                      listMsg = [];
                      if (!snapshot.hasData)
                        return CircularProgressIndicator();
                      else {
                        List<DocumentSnapshot> document =
                            snapshot.data.documents;
                        print(document.length);
                        for (int i = 0; i < document.length; i++) {
                          listMsg.add([
                            document[i]["content"],
                            document[i]["isMe"].compareTo(widget.name) == 0
                                ? false
                                : true,
                            document[i]["timestamp"],
                            document[i]["isImage"]
                          ]);
                        }
                        print(listMsg);
                        return ListView.builder(
                            reverse: true,
                            itemCount: snapshot.data.documents.length,
                            controller: listScrollController,
                            itemBuilder: (context, i) {
                              try {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Bubble(
                                      message: listMsg[i][0],
                                      notMe: listMsg[i][1],
                                      delivered: true,
                                      time: readTimestamp(
                                          int.parse(listMsg[i][2])),
                                      methodVia: 0,
                                      type: listMsg[i][3] == true ? 1 : 0,
                                    ),
                                  ],
                                );
                              } catch (RangeError) {
                                return Container(
                                  color: Colors.white,
                                );
                              }
                            });
                      }
                    }),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: widget.greet != Color(0xFF242424)
                        ? widget.greet
                        : Colors.grey.shade300,
                    borderRadius: new BorderRadius.circular(20.0),
                  ),
                  child: new TextFormField(
                    textAlign: TextAlign.start,
                    decoration: new InputDecoration(
                        filled: true,
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        hintText: "Type a message...",
                        prefixIcon: IconButton(
                          icon: Icon(
                            Icons.image,
                            size: 25.0,
                          ),
                          color: Colors.black,
                          disabledColor: Colors.grey,
                          onPressed: () => sendMessage(1),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.send,
                            size: 25.0,
                          ),
                          color: Colors.black,
                          disabledColor: Colors.grey,
                          onPressed: () => sendMessage(0),
                        )),
                    controller: textEditingController,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: widget.background == Color(0xFF242424)
                          ? widget.background
                          : widget.greet,
                      fontSize: 18.0,
                    ),
                    onSaved: (val) => msg = val,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void sendMessage(int type) async {
    //message type = 0; image type = 1;
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    String imageUrl = "";
    //TODO: if the type == 1(image), then make a post call to the imgBB and fetch the url of the image and post it as a string message.
    if (type == 1) {
      var _image = await ImagePicker.pickImage(
          source: ImageSource.gallery, maxHeight: 800, maxWidth: 800);
      print(_image.stat());
      //Compressing big images to enable successful send.
      List<int> imageBytes = _image.readAsBytesSync();
      imageUrl = base64Encode(imageBytes);
      print(imageUrl);
      // Map<String, dynamic> body = {
      //   "key": "400b0402ee29bc7eb67b70b35f836fcd",
      //   "image": imageUrl,
      // };
      // try {
      //   var response =
      //       await http.post("https://api.imgbb.com/1/upload", body: body);
      //   print(response.body);
      // } catch (e) {
      //   print(e);
      // }
    } else if (type == 0 && textEditingController.value.text != "") {
      setState(() {
        messageList(
            textEditingController.value.text, false, readTimestamp(timeStamp));
        listScrollController.animateTo(0.0,
            duration: Duration(milliseconds: 300), curve: Curves.elasticIn);
        //Refreshing widget when new message is sent or appears.
      });
    }
    var documentReference = Firestore.instance
        .collection('messages')
        .document(returnGroupId(widget.name, widget.frienduid))
        .collection(returnGroupId(widget.name, widget.frienduid))
        .document(timeStamp.toString());

    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        documentReference,
        {
          'timestamp': timeStamp.toString(),
          'content': type == 0 ? textEditingController.value.text : imageUrl,
          'isMe': widget.name,
          'isImage': type == 1,
          'receiverToken': receiverToken
          //this set isImage field to boolean true if it is an image else false if it is a message.
        },
      );
    }).whenComplete(() {
      textEditingController.clear();
      setState(() {});
    });
  }
}

class Bubble extends StatelessWidget {
  Bubble(
      {this.message,
      this.notMe,
      this.delivered,
      this.time,
      this.type = 0,
      this.methodVia = 0});
  final bool delivered;
  final bool notMe;
  final String message;
  final String time;
  final int type;
  //This describes whether the message sent is an image or a text.
  final int methodVia; //For personal chat: 0, for group chat: 1

  @override
  Widget build(BuildContext context) {
    final bg = notMe ? Colors.white : Color(0xFF27E9E1).withOpacity(0.7);
    final align = notMe ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final icon = delivered ? Icons.done_all : Icons.done;
    final double width = MediaQuery.of(context).size.width * 0.75;
    final radius = notMe
        ? BorderRadius.only(
            topRight: Radius.circular(5.0),
            bottomLeft: Radius.circular(10.0),
            bottomRight: Radius.circular(5.0),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(5.0),
            bottomLeft: Radius.circular(5.0),
            bottomRight: Radius.circular(10.0),
          );
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ImageScreen(message)));
      },
      child: type == 1
          ? Column(
              crossAxisAlignment: align,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: notMe ? Colors.white : Color(0xFF242424),
                          width: 5.0)),
                  width: width - 20,
                  height: width - 50,
                  child: Image.memory(
                    base64Decode(message),
                    fit: BoxFit.cover,
                  ),
                )
              ],
            )
          : Column(
              crossAxisAlignment: align,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(10.0),
                  padding: const EdgeInsets.all(8.0),
                  constraints: BoxConstraints(maxWidth: width, minWidth: 120.0),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: .5,
                          spreadRadius: 1.0,
                          color: Colors.black.withOpacity(.12))
                    ],
                    color: bg,
                    borderRadius: radius,
                  ),
                  child: Stack(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 48.0, bottom: 12.0),
                        child: Text(message),
                      ),
                      Positioned(
                        bottom: 0.0,
                        right: 0.0,
                        child: Row(
                          children: <Widget>[
                            Text(time,
                                style: TextStyle(
                                  color: Colors.black38,
                                  fontSize: 8.0,
                                )),
                            SizedBox(width: 3.0),
                            Icon(
                              icon,
                              size: 12.0,
                              color: Colors.black38,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class ImageScreen extends StatelessWidget {
  final String message;
  ImageScreen(this.message);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Image.memory(
          base64Decode(message),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
