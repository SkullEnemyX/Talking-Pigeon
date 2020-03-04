import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/Pages/Authentication/authentication.dart';
import 'package:talking_pigeon_x/Pages/Authentication/sign-in.dart';
import 'package:flutter/cupertino.dart';
import 'package:talking_pigeon_x/Pages/Bloc/themebloc.dart';
import 'package:talking_pigeon_x/Pages/global_configurations/config.dart';

class Profile extends StatefulWidget {
  final bool darkThemeEnabled;
  final String username;
  Profile({@required this.username, this.darkThemeEnabled});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String profilePic = "";
  String thumbnail = "";
  String fullname;
  TextEditingController _textEditingController = TextEditingController();
  bool readOnly = true;
  Icon editStatus = Icon(
    Icons.edit,
    color: Colors.grey,
  );
  Stream<QuerySnapshot> snapshot;
  Userauthentication userAuth = new Userauthentication();
  @override
  void initState() {
    super.initState();
    snapshot = readUserInfo(widget.username);
  }

  Stream<QuerySnapshot> readUserInfo(String username) {
    return Firestore.instance
        .collection("Users")
        .where("username", isEqualTo: username)
        .snapshots();
  }

  // void darkTheme() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String _theme = (prefs.getString("theme") ?? "Light");
  //   print(_theme);
  //   setState(() {
  //     if (_theme.compareTo("Dark") == 0) {
  //       greet = Colors.white;
  //       background = Color(0xFF242424);
  //       prefs.setString("theme", "Light");
  //     } else {
  //       greet = Color(0xFF242424);
  //       background = Colors.white;
  //       prefs.setString("theme", "Dark");
  //     }
  //   });
  // }

  void uploadProfilePic() async {
    var url;
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
        url = jsonObject;
        print(url);
        if (url != null) {
          await Firestore.instance
              .document("Users/${widget.username}")
              .updateData({
            "thumbnail": url["data"]["thumb"]["url"],
            "profileImage": url["data"]["image"]["url"]
          });
        }
      } catch (e) {
        throw e;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).backgroundColor,
        body: StreamBuilder<QuerySnapshot>(
            stream: snapshot,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                DocumentSnapshot documentSnapshot = snapshot.data.documents[0];
                _textEditingController.text =
                    documentSnapshot["status_for_everyone"];
                return Column(
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
                            onTap: uploadProfilePic,
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
                                autocorrect: true,
                                readOnly: readOnly,
                                textAlign: TextAlign.start,
                                textAlignVertical: TextAlignVertical.center,
                                controller: new TextEditingController.fromValue(
                                    new TextEditingValue(
                                        text: _textEditingController.text,
                                        selection: new TextSelection.collapsed(
                                            offset: _textEditingController
                                                .text.length))),
                                style: TextStyle(
                                  color:
                                      Theme.of(context).textTheme.title.color,
                                  fontSize: 18.0,
                                ),
                                onChanged: (content) {
                                  _textEditingController.text = content;
                                },
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                cursorRadius: Radius.circular(10.0),
                                cursorColor: Colors.blue,
                                maxLines: 1,
                                maxLength: 50,
                                expands: false,
                                enableSuggestions: true,
                                decoration: InputDecoration(
                                    counter: Container(),
                                    border: InputBorder.none,
                                    suffixIcon: IconButton(
                                        icon: editStatus,
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onPressed: () async {
                                          if (readOnly) {
                                            setState(() {
                                              readOnly = false;
                                              editStatus = Icon(
                                                Icons.check,
                                              );
                                            });
                                            _textEditingController.text = "";
                                          } else {
                                            setState(() {
                                              readOnly = true;
                                              editStatus = Icon(
                                                Icons.edit,
                                                color: Colors.grey,
                                              );
                                            });
                                            await Firestore.instance
                                                .document(
                                                    "Users/${widget.username}")
                                                .updateData({
                                              "status_for_everyone":
                                                  _textEditingController
                                                      .value.text
                                            });
                                          }
                                        })),
                                autofocus: true,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 10.0,
                            left: 30.0,
                          ),
                          child: Row(
                            children: <Widget>[
                              Text(
                                "Dark Mode",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).textTheme.title.color,
                                  fontSize: 25.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              CupertinoSwitch(
                                value: widget.darkThemeEnabled,
                                onChanged: (val) {
                                  bloc.changeTheme(val);
                                  Config.prefs
                                      .setBool(Config.darkModePrefs, val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Expanded(child: SizedBox()),
                    InkWell(
                      splashColor: Colors.teal,
                      borderRadius: BorderRadius.circular(20.0),
                      onTap: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        userAuth.logout();
                        prefs.setString('username', '');
                        prefs.setString('password', '');
                        await Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                      },
                      child: Material(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Theme.of(context).backgroundColor ==
                                Color(0xff242424)
                            ? Colors.white12
                            : Colors.white70,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          width: 150.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: Theme.of(context).backgroundColor !=
                                    Color(0xff242424)
                                ? [
                                    BoxShadow(
                                      blurRadius: 5.0,
                                      spreadRadius: 2.0,
                                      color: Colors.grey.shade200,
                                    ),
                                  ]
                                : null,
                            color: Theme.of(context).backgroundColor ==
                                    Color(0xff242424)
                                ? Colors.white12
                                : Colors.white70,
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "SIGN OUT",
                              style: TextStyle(
                                  color: Color(0xFF27E9E1),
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 10.0, top: 20.0),
                        child: Text(
                          "Made with ❤ in India",
                          style: TextStyle(
                              color: Theme.of(context).textTheme.title.color),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Container();
              }
            }));
  }
}
