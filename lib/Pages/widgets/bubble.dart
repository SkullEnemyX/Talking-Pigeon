import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:talking_pigeon_x/Pages/Global/timestamp.dart';
import 'package:talking_pigeon_x/Pages/Profile/ImageScreen.dart';

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
  final TimeStamp singletontimeStamp = TimeStamp();
  //This describes whether the message sent is an image or a text.
  final int methodVia; //For personal chat: 0, for group chat: 1

  @override
  Widget build(BuildContext context) {
    final double radiusCircle = 15.0;
    final bg = notMe
        ? background == Color(0XFF242424) ? Colors.white : Colors.grey.shade300
        : Theme.of(context).primaryColor.withOpacity(0.7);
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
                padding: const EdgeInsets.only(
                    top: 15.0, bottom: 10.0, right: 15.0, left: 15.0),
                constraints: BoxConstraints(maxWidth: width, minWidth: 80.0),
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
                      child: Text(
                        message,
                        style: TextStyle(
                            fontSize: 16.0,
                            color: notMe ? Colors.black : Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 0.0,
                      left: notMe ? 0.0 : null,
                      right: notMe ? null : 0.0,
                      child: Row(
                        children: <Widget>[
                          Text(
                              singletontimeStamp.currentMessageTimestamp(
                                int.parse(timestamp),
                              ),
                              style: TextStyle(
                                color: notMe ? Colors.black : Colors.white,
                                fontSize: 9.0,
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
