import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
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
        _messaging.getToken().then((token) {});
      }
    });
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
    var snap = Firestore.instance
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
        backgroundColor: widget.background,
        centerTitle: true,
        primary: true,
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
                                    time: readTimestamp(
                                        int.parse(document[i]["timestamp"])),
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
                        color: Colors.white,
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
                        borderRadius: new BorderRadius.circular(20.0),
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
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
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
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => textEditingController.clear());
    String imageUrl;
    var url;
    if (type == 1) {
      File _image = await ImagePicker.pickImage(source: source, maxWidth: 720);
      List<int> imageBytes = _image.readAsBytesSync();
      imageUrl = base64Encode(imageBytes);
      // print(imageUrl); Very bad algortihm, try not to use.
      Map<String, dynamic> body = {
        "key": "400b0402ee29bc7eb67b70b35f836fcd",
        "image": imageUrl,
      };
      try {
        setState(() {
          sending = 1;
        });
        var response =
            await http.post("https://api.imgbb.com/1/upload", body: body);
        var jsonObject = json.decode(response.body);
        url = jsonObject["data"]["url"];
      } catch (e) {
        throw e;
      }
    } else if (type == 0) {
      print(content);
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

    Firestore.instance
        .collection('messages')
        .document(returnGroupId(widget.name, widget.frienduid))
        .collection(returnGroupId(widget.name, widget.frienduid))
        .document(timeStamp.toString())
        .setData(transaction);
    setState(() {
      sending = 0;
    });
  }
}

int sending = 0;

class Bubble extends StatelessWidget {
  Bubble(
      {this.message,
      this.notMe,
      this.delivered,
      this.time,
      this.type = 0,
      this.background,
      this.methodVia = 0});
  final bool delivered;
  final bool notMe;
  final String message;
  final String time;
  final int type;
  final Color background;
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
    return type == 1
        ? Column(
            crossAxisAlignment: align,
            children: <Widget>[
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ImageScreen(message))),
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
                  // child: Image.network(
                  //   message,
                  //   loadingBuilder: (BuildContext context, Widget child,
                  //       ImageChunkEvent loadingProgress) {
                  //     if (loadingProgress == null) {
                  //       return Container(
                  //         margin: const EdgeInsets.all(10.0),
                  //         child: Card(
                  //           clipBehavior: Clip.antiAlias,
                  //           shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(20.0)),
                  //           child: child,
                  //         ),
                  //         width: width - 20,
                  //         height: width - 50,
                  //       );
                  //     }
                  //     return Container(
                  //       margin: const EdgeInsets.all(10.0),
                  //       width: width - 20,
                  //       height: width - 50,
                  //       child: Card(
                  //         clipBehavior: Clip.antiAlias,
                  //         shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(20.0)),
                  //         child: Center(
                  //           child: CircularProgressIndicator(
                  //             value: loadingProgress.expectedTotalBytes != null
                  //                 ? loadingProgress.cumulativeBytesLoaded /
                  //                     loadingProgress.expectedTotalBytes
                  //                 : null,
                  //             valueColor: new AlwaysStoppedAnimation<Color>(
                  //                 Colors.teal),
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  //   fit: BoxFit.cover,
                  // ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: align,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(5.0),
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
                      child: Text(
                        message,
                        style: TextStyle(
                            color: notMe ? Colors.black : Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 0.0,
                      right: 0.0,
                      child: Row(
                        children: <Widget>[
                          Text(time,
                              style: TextStyle(
                                color: notMe ? Colors.black : Colors.white,
                                fontSize: 8.0,
                              )),
                          SizedBox(width: 3.0),
                          Icon(
                            icon,
                            size: 12.0,
                            color: notMe ? Colors.black : Colors.white,
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
  ImageScreen(this.message, {this.background = Colors.white});

  @override
  _ImageScreenState createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(widget.message),
          minScale: PhotoViewComputedScale.contained,
        ),
      ),
    );
  }
}
