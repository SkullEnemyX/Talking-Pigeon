import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:talking_pigeon_x/Pages/HomeScreen/chatscreen.dart';
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
  Stream<QuerySnapshot> snap;
  StreamSubscription snapshotlastseen;
  @override
  void initState() {
    super.initState();
    textEditingController.clear();
    setState(() {
      snap = snapshotReturn();
      snapshotlastseen = _fetchInitDetails().listen((val) {
        DocumentSnapshot db = val.documents[0];
        setState(() {
          status = db["status"] ?? " ";
          receiverToken = db["deviceId"] ?? " ";
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

  final TextEditingController textEditingController =
      new TextEditingController();
  List listMsg = [];
  String msg;
  String receiverToken = " ";
  String status = " ";
  final ScrollController listScrollController = new ScrollController();

  Stream<QuerySnapshot> _fetchInitDetails() {
    Stream<QuerySnapshot> snap = Firestore.instance
        .collection("Users")
        .where("username", isEqualTo: "${widget.frienduid}")
        .snapshots();
    return snap;
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
      var formatHR = DateFormat("h:mm a");
      var formatDAY = DateFormat("d/M/y");
      if (diff.inDays < 1) {
        return "last seen today at " + formatHR.format(date);
      } else if (diff.inDays == 1) {
        return "last seen yesterday at " + formatHR.format(date);
      }
      return "last seen on " + formatDAY.format(date);
    }
  }

  String returnGroupId(String myid, String friendid) {
    if (myid.hashCode >= friendid.hashCode) {
      return (myid.hashCode.toString() + friendid.hashCode.toString());
    } else {
      return (friendid.hashCode.toString() + myid.hashCode.toString());
    }
  }

  Stream<QuerySnapshot> snapshotReturn() {
    final String groupId = returnGroupId(widget.name, widget.frienduid);
    Stream<QuerySnapshot> snap = Firestore.instance
        .collection('messages')
        .document(groupId)
        .collection(groupId)
        .orderBy('timestamp', descending: true)
        .snapshots();
    return snap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        elevation: 0.0,
        backgroundColor: widget.background == Color(0XFF242424)
            ? widget.background
            : Colors.grey.shade100,
        primary: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "${widget.frienduid}"
                  .toString()
                  .split(" ")[0], //Change Name to Friends name.
              style: GoogleFonts.pTSans(
                  fontSize: 25.0,
                  color: widget.greet,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              lastSeen(status),
              style: TextStyle(
                  color: greet, fontSize: 15.0, fontWeight: FontWeight.w400),
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
      body: new Container(
        color: widget.background == Color(0XFF242424)
            ? widget.background
            : Colors.grey.shade100,
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
                      List<DocumentSnapshot> document = snapshot.data.documents;
                      return ListView.builder(
                          reverse: true,
                          itemCount: snapshot.data.documents.length,
                          controller: listScrollController,
                          itemBuilder: (context, i) {
                            try {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Bubble(
                                    message: document[i]["content"],
                                    notMe: document[i]["isMe"]
                                                .compareTo(widget.name) ==
                                            0
                                        ? false
                                        : true,
                                    delivered: true,
                                    sendername: document[i]["isMe"],
                                    timestamp: document[i]["timestamp"],
                                    methodVia: 0,
                                    background: widget.background,
                                    type:
                                        document[i]["isImage"] == true ? 1 : 0,
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
              child: Row(
                children: <Widget>[
                  Container(
                    height: 45.0,
                    decoration: BoxDecoration(
                        color: widget.greet != Color(0xFF242424)
                            ? widget.greet
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(50.0)),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => sendMessage(
                              textEditingController.value.text,
                              1,
                              ImageSource.gallery),
                          icon: Icon(
                            Icons.image,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          onPressed: () => sendMessage(
                              textEditingController.value.text,
                              1,
                              ImageSource.camera),
                          icon: Icon(
                            Icons.camera,
                            color: Colors.black,
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
                        color: widget.greet != Color(0xFF242424)
                            ? widget.greet
                            : Colors.grey.shade300,
                        borderRadius: new BorderRadius.circular(50.0),
                      ),
                      child: new TextFormField(
                        textAlign: TextAlign.start,
                        decoration: new InputDecoration(
                            filled: true,
                            border: InputBorder.none,
                            fillColor: Colors.transparent,
                            hintText: "Type a message",
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.send,
                                size: 25.0,
                              ),
                              color: Colors.black,
                              disabledColor: Colors.grey,
                              onPressed: () =>
                                  textEditingController.value.text != ""
                                      ? sendMessage(
                                          textEditingController.value.text,
                                          0,
                                          ImageSource.gallery)
                                      : null,
                            )),
                        controller: textEditingController,
                        keyboardType: TextInputType.multiline,
                        onFieldSubmitted: (message) => message != ""
                            ? sendMessage(message, 0, ImageSource.gallery)
                            : null,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.openSans(
                          color: widget.background == Color(0xFF242424)
                              ? widget.background
                              : widget.greet,
                          //fontSize: 18.0,
                        ),
                        onSaved: (val) => msg = val,
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

  String readTimestamp(int timestamp) {
    var format = new DateFormat('HH:mm a');
    var date = new DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
    var time = '';
    format = DateFormat(" d/M/y, HH:mm a");
    time = format.format(date);
    return time;
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
      'receiverToken': receiverToken
      //this set isImage field to boolean true if it is an image else false if it is a message.
    };

    await Firestore.instance
        .collection('messages')
        .document(returnGroupId(widget.name, widget.frienduid))
        .collection(returnGroupId(widget.name, widget.frienduid))
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

class Bubble extends StatelessWidget {
  Bubble(
      {this.message,
      this.notMe,
      this.delivered,
      this.timestamp,
      this.sendername,
      this.type = 0,
      this.background,
      this.methodVia = 0});
  final bool delivered;
  final bool notMe;
  final String message;
  final String timestamp;
  final int type;
  final String sendername;
  final Color background;
  //This describes whether the message sent is an image or a text.
  final int methodVia; //For personal chat: 0, for group chat: 1

  String readTimestamp(int timestamp) {
    var format = new DateFormat('HH:mm a');
    var date = new DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
    var time = '';
    format = DateFormat(" d/M/y, h:mm a");
    time = format.format(date);
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final double radiusCircle = 20.0;
    final bg = notMe
        ? background == Color(0XFF242424) ? Colors.white : Colors.grey.shade300
        : Color(0xFF27E9E1).withOpacity(0.7);
    final align = notMe ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final icon = delivered ? Icons.done_all : Icons.done;
    final double width = MediaQuery.of(context).size.width * 0.75;
    final radius = BorderRadius.all(Radius.circular(radiusCircle));
    return type == 1
        ? Column(
            crossAxisAlignment: align,
            children: <Widget>[
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ImageScreen(
                          message,
                          background: background,
                          timestamp: timestamp,
                          username: sendername,
                        ))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Container(
                    margin: const EdgeInsets.all(10.0),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      child: CachedNetworkImage(
                        imageUrl: message,
                        fit: BoxFit.cover,
                      ),
                    ),
                    width: width - 20,
                    height: width - 50,
                  ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: align,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(
                    left: 10, top: 5.0, bottom: 5.0, right: 10.0),
                padding: const EdgeInsets.all(10.0),
                constraints: BoxConstraints(maxWidth: width, minWidth: 130.0),
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
                  alignment:
                      notMe ? Alignment.centerLeft : Alignment.centerRight,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(right: 0.0, bottom: 15.0),
                      child: Text(message,
                          style: GoogleFonts.pTSans(
                              fontSize: 16.0,
                              color: notMe
                                  ? Colors.black
                                  : background == Color(0XFF242424)
                                      ? Colors.white
                                      : Colors.black)),
                    ),
                    Positioned(
                      bottom: 0.0,
                      right: 0.0,
                      child: Row(
                        children: <Widget>[
                          Text(readTimestamp(int.parse(timestamp)),
                              style: TextStyle(
                                color: notMe
                                    ? Colors.black
                                    : background == Color(0XFF242424)
                                        ? Colors.white
                                        : Colors.black,
                                fontSize: 9.0,
                              )),
                          SizedBox(width: 3.0),
                          Icon(
                            icon,
                            size: 12.0,
                            color: notMe
                                ? Colors.black
                                : background == Color(0XFF242424)
                                    ? Colors.white
                                    : Colors.black,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
  }
}

class ImageScreen extends StatefulWidget {
  final String message;
  final Color background;
  final String username;
  final String timestamp;
  ImageScreen(this.message,
      {this.background = Colors.white, this.username, this.timestamp});

  @override
  _ImageScreenState createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  String readTimestamp(int timestamp) {
    var format = new DateFormat('HH:mm a');
    var date = new DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
    var time = '';
    format = DateFormat(" d/M/y, h:mm a");
    time = format.format(date);
    return time;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "${widget.username}", //Change Name to Friends name.
              style: GoogleFonts.pTSans(
                  fontSize: 25.0,
                  color: background == Color(0xFF242424)
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              readTimestamp(int.parse(widget.timestamp)),
              style: TextStyle(
                  color: background == Color(0xFF242424)
                      ? Colors.white
                      : Colors.black,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor:
            background == Color(0xFF242424) ? Colors.black : Colors.white,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color:
                  background == Color(0xFF242424) ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
      body: Container(
        child: PhotoView(
          backgroundDecoration: BoxDecoration(
              color: background == Color(0xFF242424)
                  ? Colors.black
                  : Colors.white),
          imageProvider: CachedNetworkImageProvider(widget.message),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered,
        ),
      ),
    );
  }
}
