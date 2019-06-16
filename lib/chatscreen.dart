import 'dart:io';
import 'package:flutter/material.dart';
import 'package:talking_pigeon_x/authentication.dart';
import 'package:talking_pigeon_x/chatpage.dart';
import 'package:intl/intl.dart';
import 'package:talking_pigeon_x/sign-in.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
   int hour;
   Userauthentication userAuth = new Userauthentication();
   UserData userData = new UserData();
   bool _loadingInProgress;
   String lastMessage;
   String friendid;


  @override
    void initState() {
      super.initState();
      getSharedPrefs();
      _initx();
    }

    
  
  _initx() {
    fetchTime();
    darkTheme();
    friendfunc();

  }

    Future<Null> getSharedPrefs() async {
    _loadingInProgress = true;
    final DocumentReference documentReference = Firestore.instance.document("Users/${widget.username}");
    globalUsername = "${widget.username}";
    await documentReference.get().then((snapshot){
    if(snapshot.exists)
    {
      name =  snapshot.data['name'];

    }
    setState(() {
      _loadingInProgress = false;
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
    print(flist);

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
    if (_loadingInProgress==true) {
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
                        "$greeting, "+ "$name".toString().split(" ")[0]
                        ,style: TextStyle(
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
                                       print(document[0]["timestamp"]);
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

  void menuList(String value)
  {
    if(value=='a'){
      darkTheme();
    }
    else if(value == 'b'){
      userAuth.logout(userData);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
    }
    else if(value=='c'){ 
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(),
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
  
  Future<List<String>> addfriends() async{
  final DocumentReference documentReference = Firestore.instance.document("Users/$globalUsername");
  
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
    return userList.where((p)=>p.compareTo(s)==0).toList(); //If exact match needed on query.
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
                   var list = await addfriends();
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