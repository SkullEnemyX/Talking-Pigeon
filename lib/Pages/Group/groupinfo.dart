import 'package:flutter/material.dart';

class GroupInfo extends StatefulWidget {
  final String groupname;
  final List<String> members;
  final String imageUrl;
  final String description;

  const GroupInfo(
      {Key key, this.groupname, this.members, this.imageUrl, this.description})
      : super(key: key);
  @override
  _GroupInfoState createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  @override
  Widget build(BuildContext context) {
    return Container();
    // return Scaffold(
    //   appBar: AppBar(
    //     elevation: 0.0,
    //     backgroundColor: Theme.of(context).appBarTheme.color,
    //     primary: true,
    //     title: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: <Widget>[
    //         Text(
    //           "${widget.username}"
    //               .toString()
    //               .split(" ")[0], //Change Name to Friends name.
    //           style: TextStyle(
    //             fontSize: 25.0,
    //             color: Theme.of(context).textTheme.title.color,
    //             fontWeight: FontWeight.w600,
    //           ),
    //         ),
    //         Text("",
    //           style: TextStyle(
    //               color: Theme.of(context).textTheme.title.color,
    //               fontSize: 15.0,
    //               fontWeight: FontWeight.w400),
    //         ),
    //       ],
    //     ),
    //     leading: new IconButton(
    //       icon: Icon(
    //         Icons.arrow_back,
    //         color: Theme.of(context).iconTheme.color,
    //       ),
    //       onPressed: () async {
    //         Navigator.pop(context);
    //       },
    //     ),
    //   ),,
    // );
  }
}
