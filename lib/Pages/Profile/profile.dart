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

class Profile extends StatefulWidget {
  final bool darkThemeEnabled;
  final String username;
  Profile({@required this.username, this.darkThemeEnabled});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController _textEditingController = TextEditingController();
  bool readOnly = true;
  Icon editStatus = Icon(
    Icons.edit,
    color: Colors.grey,
  );
  bool darkThemeEnabled;
  Stream<QuerySnapshot> snapshot;
  Userauthentication userAuth = new Userauthentication();
  SharedPreferences prefs;
  @override
  void initState() {
    super.initState();
    snapshot = readUserInfo(widget.username);
    darkThemeEnabled = widget.darkThemeEnabled ?? false;
  }

  Stream<QuerySnapshot> readUserInfo(String username) {
    return Firestore.instance
        .collection("Users")
        .where("username", isEqualTo: username)
        .snapshots();
  }

  setDarkTheme(bool val) async {
    prefs = await SharedPreferences.getInstance();
    prefs.setBool("DarkMode", val);
  }

  setThemeColor(Color themeColor) async {
    prefs = await SharedPreferences.getInstance();
    prefs.setInt('color', themeColor.value);
  }

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

  Widget themeColor() {
    List<Color> colors = [
      Colors.blueAccent,
      Colors.indigo,
      Colors.teal,
      Colors.deepOrangeAccent,
      Colors.pinkAccent,
    ];
    final double circleSize = 30.0;
    List<Widget> colorsButtons = List<Widget>();
    for (int i = 0; i < colors.length; i++) {
      colorsButtons.add(
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 5.0,
          ),
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: colors[i],
            shape: BoxShape.circle,
          ),
          child: InkWell(
            splashColor: Colors.transparent,
            onTap: () {
              colorBloc.changeColorTheme(colors[i]);
              setThemeColor(colors[i]);
            },
            radius: 100.0,
          ),
        ),
      );
    }
    return Row(
      children: <Widget>[
        Text(
          "Themes",
          style: TextStyle(
            color: Theme.of(context).textTheme.title.color,
            fontSize: 25.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(
          width: 30.0,
        ),
        Row(
          children: colorsButtons,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder<QuerySnapshot>(
          stream: snapshot,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              DocumentSnapshot documentSnapshot = snapshot.data.documents[0];
              _textEditingController.text =
                  documentSnapshot["status_for_everyone"];
              return SingleChildScrollView(
                child: Column(
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
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  width: 2.0,
                                  color: Theme.of(context).canvasColor,
                                ),
                              ),
                              padding:
                                  const EdgeInsets.only(left: 20.0, right: 5.0),
                              child: TextFormField(
                                autocorrect: true,
                                readOnly: readOnly,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .title
                                        .color),
                                textAlignVertical: TextAlignVertical.center,
                                controller: new TextEditingController.fromValue(
                                  new TextEditingValue(
                                    text: _textEditingController.text,
                                    selection: new TextSelection.collapsed(
                                        offset:
                                            _textEditingController.text.length),
                                  ),
                                ),
                                onChanged: (content) {
                                  _textEditingController.text = content;
                                },
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                cursorRadius: Radius.circular(10.0),
                                cursorColor: Colors.blue,
                                maxLines: 2,
                                minLines: 1,
                                maxLength: 100,
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
                                value: darkThemeEnabled,
                                onChanged: (val) {
                                  bloc.changeTheme(val);
                                  setDarkTheme(val);
                                  setState(() {
                                    darkThemeEnabled = !darkThemeEnabled;
                                  });
                                },
                              ),
                            ],
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
                            child: themeColor()),
                      ],
                    ),
                    SizedBox(
                      height: 100.0,
                    ),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        width: 150.0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).buttonColor,
                          border: Border.all(color: Colors.black, width: 1.0),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "SIGN OUT",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
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
                ),
              );
            } else {
              return Container();
            }
          }),
    );
  }
}
