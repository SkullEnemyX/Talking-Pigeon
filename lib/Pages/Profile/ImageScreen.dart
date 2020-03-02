import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:talking_pigeon_x/Pages/HomeScreen/chatscreen.dart';

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
              style: TextStyle(
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
