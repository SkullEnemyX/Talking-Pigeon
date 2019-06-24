import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talking_pigeon_x/authentication.dart';
import 'package:talking_pigeon_x/chatpage.dart';
import 'package:intl/intl.dart';
import 'package:talking_pigeon_x/groupchat.dart';
import 'package:talking_pigeon_x/sign-in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var globalUsername;
Color greet ;
Color background ;
var friendlist ;
List<String> flist = [];
List<String> fname = [];

class ChatScreen extends StatefulWidget {
  final String username;
  ChatScreen({Key key, this.username}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

    //Make it dynamic
   String greeting = "Good Afternoon"; 
   String name;
   String theme = "Dark Theme"; 
   int gvalue=0 ;
   TextEditingController textEditingController = TextEditingController();
   int hour;
   Userauthentication userAuth = new Userauthentication();
   UserData userData = new UserData();
   bool loadingInProgress;
   String lastMessage;
   String friendid;
   var childButtons = List<UnicornButton>();


  @override
    void initState() {
      super.initState();
      getSharedPrefs();
      _initx();
      insertUnicornButtons();
    }

    
  
  _initx() {
    fetchTime();
    darkTheme();
    friendfunc();

  }

    Future<Null> getSharedPrefs() async {
    loadingInProgress = true;
    final DocumentReference documentReference = Firestore.instance.document("Users/${widget.username}");
    globalUsername = "${widget.username}";
    await documentReference.get().then((snapshot){
    if(snapshot.exists)
    {
      name =  snapshot.data['name'];

    }
    setState(() {
      loadingInProgress = false;
    });
  });}

    Future<List<String>> friendfunc() async{
    DocumentReference reference = Firestore.instance.document("Users/${widget.username}");
    await reference.get().then((snapshot)
    {
      if(snapshot.exists)
      friendlist = snapshot.data["friends"];
    });
    if(flist.isNotEmpty)
      flist.clear();
    for(int i=0;i<friendlist.length;i++)
    {
      flist.add(friendlist[i].toString());
    }
    friendlist = null;

    return flist.reversed.toList();
  }

  Future<String> fetchName() async{
    String friendName;
    return friendName;
  }

  returnGroupId(String myid,String friendid){
    if(myid.hashCode>=friendid.hashCode)
    {
      return(myid.hashCode.toString()+friendid.hashCode.toString());
    }
    else
    {
      return(friendid.hashCode.toString()+myid.hashCode.toString());
    }
  }

  String readTimestamp(int timestamp) {
    var now = new DateTime.now();
    var format = new DateFormat('HH:mm a');
    var date = new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 0 || diff.inSeconds > 0 && diff.inMinutes == 0 || diff.inMinutes > 0 && diff.inHours == 0 || diff.inHours > 0 && diff.inDays == 0) {
      time = format.format(date);
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = diff.inDays.toString() + ' DAY AGO';
      } else {
        time = diff.inDays.toString() + ' DAYS AGO';
      }
    } else {
      if (diff.inDays == 7) {
        time = (diff.inDays / 7).floor().toString() + ' WEEK AGO';
      } else {

        time = (diff.inDays / 7).floor().toString() + ' WEEKS AGO';
      }
    }

    return time;
  }

  Stream<QuerySnapshot> fetchMessages(String friendID) {
    Stream<QuerySnapshot> snap = Firestore.instance.collection('messages')
                                          .document(returnGroupId(globalUsername, friendID))
                                          .collection(returnGroupId(globalUsername,friendID))
                                          .orderBy('timestamp', descending: true)
                                          .limit(1)
                                          .snapshots();
    return snap;
  }

  Widget _buildBody() {
    if (loadingInProgress==true) {
      return new Container(
        color: background,
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SpinKitDoubleBounce(
              color: Color(0xFF27E9E1),
              size: 60.0,
            ),
            Padding(
              padding: new EdgeInsets.symmetric(vertical: 20.0),
            ),
            Text(
              "TALKING PIGEON",style: TextStyle(fontSize: 28.0,color: greet,wordSpacing: 5.0),
            )
          ],
        )),
      );
    }
    else
    {
     return Container(
          color: background,
          child: new Column(
            children: <Widget>[
              new Padding(
                padding: EdgeInsets.only(top: 30.0)
              ),
               Row(
                 children: <Widget>[
                   new Padding(
                     padding: EdgeInsets.only(left: 25.0)
                   ),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: <Widget>[
                       new Text(
                        "$greeting, "+ "$name".toString().split(" ")[0],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 27.0,
                          color: greet,
                        ),),
                        new Padding(
                          padding: EdgeInsets.only(top: 5.0,left: 30.0),
                        ),
                        new Text(
                          "Let's resume conversing...",
                          style: TextStyle(
                            color: Color(0xFF808080)
                          )
                        )
                     ],
                   ),
                 ],
               ),
               new Expanded(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                  ),
                       Expanded(
                    child: FutureBuilder(
                          future: friendfunc(),
                          builder: (BuildContext context,AsyncSnapshot snapshot)
                          {
                        if(snapshot.connectionState == ConnectionState.done)
                        if(snapshot.hasData){
                         return ListView.builder(
                         itemCount: snapshot.data?.length??0,
                         itemBuilder: (context,i){
                         return Column(
                           children: <Widget>[
                           Dismissible(
                             key: new Key(snapshot.data[i]),
                             direction: DismissDirection.endToStart,
                             background: Container(
                               color: Colors.red,
                               height: 20.0,
                               child: Center(child: Text("Remove friend: ${snapshot.data[i]}",style: TextStyle(fontWeight: FontWeight.bold),),),
                             ),
                             onDismissed: (direction){
                              
                          setState(() async{
                            var list = await friendfunc();
                              list.removeAt(i);
                              Map<String,dynamic> peopledata = <String,dynamic>{
                            "friends" : list,
                                };
                             await Firestore.instance.document("Users/$globalUsername").updateData(peopledata).whenComplete(()
                          {}).catchError((e)=>print(e));
                          });
                         
                             },
                              child: Column(
                                children: <Widget>[
                                   StreamBuilder(
                                     stream: fetchMessages(snapshot.data[i]),
                                     builder: (context, snap) {
                                       if(!snap.hasData) return Container();
                                       else
                                       {
                                      var document = snap.data.documents;
                                       lastMessage = document[0]["content"];
                                       return ListTile(
                                      trailing: Text(document[0]["timestamp"],style: TextStyle(
                                        color: greet
                                      ),),
                                       leading: Container(
                                         decoration: BoxDecoration(
                                           border: Border.all(
                                             width: 2.0,
                                             color: Color(0xFF27E9E1),
                                           ),
                                           shape: BoxShape.circle
                                         ),
                                         child:
                                           new CircleAvatar(
                                             radius: 25.0,
                                             backgroundColor: background,
                                             foregroundColor: Color(0xFF27E9E1),
                                             child: Text(snapshot.data[i][0].toUpperCase(),style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20.0),),
                                           ),

                                       ),
                                       onTap:(){
                                         //Add change if new list to be made of recent contact. 
                                         Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatPage(
                                         name: globalUsername,
                                         greet: greet,
                                         background: background,
                                         frienduid: snapshot.data[i],)));},
                                       title: Text(
                                             snapshot.data[i],
                                             style: TextStyle(
                                               color: greet,
                                               fontSize: 20.0,
                                               fontWeight: FontWeight.bold
                                             ),
                                       ),
                                       subtitle: Container(
                                         padding: EdgeInsets.only(top: 5.0),
                                         child: new Text(
                                           "$lastMessage",
                                           style: TextStyle(
                                             color: Colors.grey,
                                             fontSize: 15.0,
                                           ),
                                         ),
                                       ),
                             );}
                                     }
                                   ),
                             
                                ],
                              ),
                           
                            ),
                           ],
                         );}
                        );}
                          else
                          {

                            return Center(
                             child: Text("Add new friends to start the conversation",style: TextStyle(color: greet,),),
                            );
                          }
                          else
                          {
                            return Center(child: SpinKitDoubleBounce(
                              size: 60.0,
                              color: Color(0xFF27E9E1),
                            ));
                          }
                          }
                        )
                 )
                                   ],
                                 ),
                               )
                               ],
                               
                             ),
                           ) ;
    }}

  fetchTime()
  {
    DateTime now = DateTime.now();
    hour = int.parse(DateFormat('kk').format(now));
    
    if(hour >= 0 && hour < 12){
      greeting = "Good Morning";
    }
    else if(hour >= 12 && hour < 17){
      greeting = "Good Afternoon";
    }
    else{
      greeting = "Good Evening";
    }
    if(hour < 17){
      gvalue = 1;
    }
    else{
      gvalue = 0;
    }
  }

  void darkTheme() async
  {
      setState(() {
        if(gvalue == 0){
        greet = Color(0xFFFFFFFF);
        background = Color(0xFF242424);
        theme = "Light Theme";
        gvalue = 1;
      }
      else if(gvalue==1){
        greet = Color(0xFF242424);
        background = Color(0xFFFFFFF);
        theme = "Dark Theme";
         gvalue = 0;
      }   
                }); 
  }

  void menuList(String value) async
  {
    if(value=='a'){
      darkTheme();
    }
    else if(value == 'b'){
      userAuth.logout(userData);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('username', '');
      prefs.setString('password', '');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginScreen()));
    }
    else if(value=='c'){ 
      exit(0);
    }
  }

  insertUnicornButtons(){
    

    childButtons.add(UnicornButton(
        hasLabel: true,
        labelText: "Create a team",
        currentButton: FloatingActionButton(
          heroTag: "train",
          backgroundColor: Colors.redAccent,
          mini: true,
          child: Icon(Icons.group),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context){
                return AlertDialog(
                  title: Text("What is your team called?"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: textEditingController,
                        autofocus: true,
                      ),
                    SizedBox(
                      height: 15.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (){
                              Navigator.of(context).pop();
                              textEditingController.clear();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                               decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12.0)
                                ),
                              child: Text("Cancel",
                              style: TextStyle(
                                color: greet,
                                fontSize: 15.0,
                              ),),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (){
                              Navigator.of(context).pop();
                              print(textEditingController.value.text);
                              Navigator.of(context).push(MaterialPageRoute(builder: (context)=>GroupChat(
                                groupName: textEditingController.value.text,
                                admin: globalUsername,
                                greet: greet,
                                background: background,
                                username: globalUsername,
                              ))).whenComplete((){
                                textEditingController.clear();
                              });
                            },
                            child:Container(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                decoration: BoxDecoration(
                                  color: Color(0xFF27E9E1),
                                  borderRadius: BorderRadius.circular(12.0)
                                ),
                                child: Text("Create",
                                style: TextStyle(
                                  color: greet,
                                  fontSize: 15.0,
                                ),),
                            ),
                          ),
                        )
                      ],
                    )
                    ],
                  ),
                );
              }
            );
          },
        )));

    childButtons.add(UnicornButton(
        labelText: "Chat with a person",
        hasLabel: true,
        currentButton: FloatingActionButton(
            heroTag: "plane",
            backgroundColor: Colors.blue,
            mini: true,
            onPressed: (){
              showSearch(
                  context: context,delegate: UserSearch());
            },
            child: Icon(Icons.person))));
    
    childButtons.add(UnicornButton(
        labelText: "Flip theme",
        hasLabel: true,
        currentButton: FloatingActionButton(
            heroTag: "planex",
            backgroundColor: Colors.greenAccent,
            mini: true,
            onPressed: (){
              darkTheme();
            },
            child: Icon(Icons.flip_to_front))));

  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: UnicornDialer(
          childButtons: childButtons,
          backgroundColor: Colors.transparent,
          parentButtonBackground: Color(0xFF27E9E1),
          parentButton: Icon(Icons.add),
          orientation: UnicornOrientation.VERTICAL,
        ),
        appBar: new AppBar(
          backgroundColor: background,
          centerTitle: true,
          title: Text("Talking Pigeon",style: TextStyle(color: greet,fontSize: 25.0,),),
          leading: new PopupMenuButton<String>(
            onSelected: menuList,
            icon: new Icon(Icons.menu,color: Color(0xFF27E9E1),size: 30.0,),
              itemBuilder: (BuildContext context)=><PopupMenuItem<String>>[
                PopupMenuItem<String>(
                value: 'a',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text("$theme"),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'b',
                child: ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text("Sign Out"),
                ),),
              const PopupMenuItem<String>(
                value: 'c',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text("Exit"),
                ),
              
              ),
              ],
          ),
          elevation: 0.0,
          actions: <Widget>[
            new IconButton(
              icon: new Icon(
                Icons.search,
                size: 30.0,
              ),
              onPressed: (){
                showSearch(
                  context: context,delegate: UserSearch(
                  )
                );
              },
              color: Color(0xFF27E9E1),
            ),
            Padding(
              padding: EdgeInsets.only(right: 5.0),
            ),
            
          ],
        ),
        body: _buildBody()
         );
  }
}
                  

  var friends;
  var users;

class UserSearch extends SearchDelegate<String>{

  //final DocumentReference documentReference = Firestore.instance.document("Users/$globalUsername");
  final CollectionReference collectionReference = Firestore.instance.collection("Users");
  List<String> userList = ["null"];
  List<String> presentList = ["null"];
  List<String> friendSuggestion = [];
  
  Future<List<String>> addfriends(String username) async{
  final DocumentReference documentReference = Firestore.instance.document("Users/$username");
  
   await documentReference.get().then((snapshot){
      if(snapshot.exists)
      {
         friends = snapshot.data['friends'];
      }
      else
      {
        friendSuggestion = [];
      } 
    });
    if(friendSuggestion.isNotEmpty)
    {
         friendSuggestion.clear();
         for(int i=0;i<friends.length;i++)
         {
           friendSuggestion.add(friends[i].toString());
         }}
     return friendSuggestion;}

  Future<List<String>> testfunc() async{
  final DocumentReference documentReference = Firestore.instance.document("Users/$globalUsername");
  
   await documentReference.get().then((snapshot){
      if(snapshot.exists)
      {
         friends = snapshot.data['friends'];
      } 
    });
    if(friendSuggestion.isNotEmpty)
         friendSuggestion.clear();
         for(int i=0;i<friends.length;i++)
         {
           friendSuggestion.add(friends[i].toString());
         }
     return friendSuggestion;}
Future<List<String>> checkpart2(String s) async{
    DocumentReference reference = Firestore.instance.document("People/People");
    await reference.get().then((snapshot)
    {
      if(snapshot.exists)
      {
        users = snapshot.data["People"];
      }
      if(userList.isNotEmpty)
      userList.clear();
      for(int i=0;i<users.length;i++)
    {
      userList.add(users[i].toString());
    }
    userList.remove(globalUsername);
    });
    //print(userList.where((p)=>p.startsWith(s)).toList()); Used in case we want to return query beginning
    return userList.where((p)=>p.startsWith(s)).toList(); //If exact match needed on query.
  }

  @override
  List<Widget> buildActions(BuildContext context) {

    return[
      IconButton(icon: Icon(Icons.clear),onPressed: (){
      },)
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: AnimatedIcon(icon: AnimatedIcons.menu_arrow,progress: transitionAnimation,),onPressed: (){
      close(context,null);
    },);
  }

  

  @override
  Widget buildResults(BuildContext context) {
  }

  @override
  Widget buildSuggestions(BuildContext context) {

   // presentList = query.isEmpty?friendSuggestion:userList.where((word)=>word.startsWith(query)).toList();

    return query.isEmpty? FutureBuilder(
      future: testfunc(),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if(snapshot.connectionState == ConnectionState.done)
       return ListView.builder(
      itemBuilder: (context,index) => 
      InkWell(
        splashColor: Color(0xFF27E9E1),
        onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatPage(
                           name: globalUsername,
                           greet: greet,
                           background: background,
                           frienduid: snapshot.data[index],))),
              child: Container(
                child: 
                  Column(
          children: <Widget>[
            ListTile(
                  leading: Icon(Icons.person),
                  title: Text(snapshot.data[index]),
            ),
            Padding(
                  padding: EdgeInsets.only(top: 2.0),
            ),
            Divider(
                  color: Colors.grey,
                  height: 2.0,
                  indent: 70.0,
            )
          ],
        ),
              ),
      ),
      itemCount: snapshot.data?.length ?? 0,
    );
    else
    {
      return Center(child: SpinKitDoubleBounce(
                          size: 60.0,
                          color: Color(0xFF27E9E1),
                        ));
    }
      }
    ):
    FutureBuilder(
      future: checkpart2(query),
      builder: (BuildContext context, AsyncSnapshot snapshot){
       if(snapshot.connectionState==ConnectionState.done)
       return ListView.builder(
      itemBuilder: (context,index) => 
      InkWell(
        splashColor: Color(0xFF27E9E1),
        onTap: () async { Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatPage(
                           name: globalUsername,
                           greet: greet,
                           background: background,
                           frienduid: snapshot.data[index],)));
                  //Adding people to each other's friendlist if one selects the name of the user.
                   var list = await addfriends(globalUsername);
                   if(!list.contains(snapshot.data[index]))
                   {
                     list.add(snapshot.data[index].toString());
                     DocumentReference ref = Firestore.instance.document("Users/$globalUsername");
                     Map<String,dynamic> peopledata = <String,dynamic>{
                      "friends" : list,
                            };
                      await ref.updateData(peopledata).whenComplete(()
                      {}).catchError((e)=>print(e));
                   }
                  list = await addfriends(snapshot.data[index]);
                   if(!list.contains(globalUsername))
                   {
                     list.add(globalUsername);
                     DocumentReference ref = Firestore.instance.document("Users/${snapshot.data[index]}");
                     Map<String,dynamic> peopledata = <String,dynamic>{
                      "friends" : list,
                            };
                      await ref.updateData(peopledata).whenComplete(()
                      {}).catchError((e)=>print(e));
                   }
                  },
              child: Container(
                child: 
                  Column(
          children: <Widget>[
            ListTile(
                  leading: Icon(Icons.person),
                  title: Text(snapshot.data[index]),
            ),
            Padding(
                  padding: EdgeInsets.only(top: 2.0),
            ),
            Divider(
                  color: Colors.grey,
                  height: 2.0,
                  indent: 70.0,
            )
          ],
        ),
              ),
      ),
      itemCount: snapshot.data?.length??0,
    );
    else
    {
      return Center(child: SpinKitDoubleBounce(
                          size: 60.0,
                          color: Color(0xFF27E9E1),
                        ));
    }
      }
    );
  }

}