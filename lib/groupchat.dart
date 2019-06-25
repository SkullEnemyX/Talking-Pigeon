import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:talking_pigeon_x/chatpage.dart';


class GroupChat extends StatefulWidget {
  final String groupName;
  final String admin;
  final String username;
  final String groupId;
  final Color greet,background;
  GroupChat({@required this.groupName,this.admin,@required this.background,@required this.greet,@required this.username,@required this.groupId});
  @override
  _GroupChatState createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {

  String groupName;
  String groupId;
  List<String> member;
  var snap;
  final TextEditingController textEditingController = new TextEditingController();
  List listMsg = [];
  String msg;
  final ScrollController listScrollController = new ScrollController();

  Stream<QuerySnapshot> createGroup(){
    var snapshot = Firestore.instance
                                    .collection('messages')
                                    .document(groupId)
                                    .collection(groupId)
                                    .orderBy('timestamp', descending: true)
                                    .limit(50)
                                    .snapshots();
    return snapshot;
  }

  messageList(String msg,bool notme,String timestamp){
    if(listMsg.length>=20)
    {
      listMsg.removeAt(0);
    }
    listMsg.add([msg,notme,timestamp]);
    return listMsg;
  }

  runTransactionToAddMembers(String uname,String groupId){
    List<String> groups;
    DocumentReference docRef = Firestore.instance.document("Users/$uname");
    docRef.get().then((onValue){
      if(onValue!=null)
      groups = onValue.data["groups"];
    }).catchError((w)=>throw(w));
    groups.add(groupId);
    docRef.updateData({
      'groups': groups
    });
  }

  void sendMessage() async{
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    if(textEditingController.value.text!="")
      {
  setState(() {
   messageList(textEditingController.value.text,false,time());
   listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  //Refreshing widget when new message is sent or appears. 
  });
  var documentReference = Firestore.instance
  .collection('messages')
  .document(groupId)
  .collection(groupId)
  .document(timeStamp.toString());

  Firestore.instance.runTransaction((transaction) async {
  await transaction.set(
  documentReference,
  {
  'sender': widget.username,
  'timestamp': timeStamp.toString(),
  'content': textEditingController.value.text,
                },);
          }).whenComplete((){textEditingController.clear();
                  setState(() {
                  });
        });
  }
  setState(() {
  });
  }

  saveGroupInfo(String username) async{
    var listOfGroups = [];
    var l = [];
    List<dynamic> map = [];
    await Firestore.instance.document("Users/$username").get().then((onValue){
      if(onValue.exists){
        map.addAll(onValue.data['groups']);
        for(int i=0;i<map.length;i++){
          map[i].forEach((m,f)=>l.add(m));
        }
        print(l);
        if(!l.contains(groupId)){
          map.add({groupId : groupName});
          onValue.reference.updateData({'groups' : map});
        }
      }
    });
    listOfGroups.forEach((f)=>print(f));
  }

  @override
  void initState() {
    super.initState();
    groupId = widget.groupId;
    groupName = widget.groupName;
    saveGroupInfo(widget.username);
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
        appBar: new AppBar(
          elevation: 0.0,
          backgroundColor: widget.background,
          centerTitle: true,
          title: new Text("${widget.groupName}",//Change Name to Friends name.
          style: TextStyle(fontSize: 23.0,color: widget.greet),),
          leading: new IconButton(
            icon: Icon(Icons.arrow_back,color: Color(0xFF27E9E1),),
            onPressed: () async{
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[
            IconButton(
              onPressed: (){
                showSearch(
                context: context,
                delegate: AddMembers(
                  groupId: groupId,
                  groupName: groupName,
                  username: widget.username
                )
              );},
              icon: Icon(Icons.add,color: Color(0XFF27E9E1),),
            )
          ],
        ),
        body: new Container(
          color: widget.background,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Flexible(
                child:StreamBuilder(
                  stream: createGroup(),
                  builder: (context,snapshot)
                  {
                    listMsg = [];
                    if(!snapshot.hasData) return CircularProgressIndicator();
                    else{
                      List<DocumentSnapshot> document = snapshot.data.documents;
                      for(int i=0;i<document.length;i++)
                      {
                        listMsg.add([document[i]["content"],
                        document[i]["sender"].compareTo(widget.username)==0?false:true,
                        document[i]["timestamp"]]);
                      }
                      return ListView.builder(
                        reverse: true,
                        itemCount: snapshot.data.documents.length,
                        controller: listScrollController,
                        itemBuilder: (context,i)
                        {
                         try{
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                    Presentmessage(message: listMsg[i][0],
                                    notme: listMsg[i][1],
                                    delivered: true,
                                    time: listMsg[i][2],),
                              ],
                            );
                         }
                         catch(RangeError)
                      {
                       return Container(
                         color: Colors.white,
                       );
                      }
                          }
                      );
                    }
                  }
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                            child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: widget.greet != Color(0xFF242424)?widget.greet:Colors.grey.shade300,
                    borderRadius: new BorderRadius.circular(20.0),
                  ),
                  child: new TextFormField(
                                        textAlign: TextAlign.start,
                                        decoration: new InputDecoration(
                                          filled: true,
                                          border: InputBorder.none,
                                          fillColor: Colors.transparent,
                                          hintText: "Type a message...",
                                          suffixIcon: IconButton(
                                            icon: Icon(Icons.send,size: 25.0,),
                                            color: Colors.black,
                                            disabledColor: Colors.grey,
                                            onPressed: sendMessage,
                                          )
                                        ),
                                        controller: textEditingController,
                                        keyboardType: TextInputType.multiline,
                                        textCapitalization: TextCapitalization.words,
                                        style: TextStyle(color: widget.background == Color(0xFF242424)?widget.background:widget.greet,fontSize: 18.0,),
                                        onSaved: (val)=> msg = val,
                                      ),
                ),
              ),
            ],
          ),
        ),

      );
  }
}

class AddMembers extends SearchDelegate<String>{
  final String username;
  final String groupId;
  final String groupName;
  AddMembers({this.username,this.groupId,this.groupName});
  var friends;

  final CollectionReference collectionReference = Firestore.instance.collection("Users");
  List<String> userList = ["null"];
  List<String> presentList = ["null"];
  List<String> friendSuggestion = [];
  var users;

  saveGroupInfo(String username) async{
    var listOfGroups = [];
    var l;
    List<dynamic> map = [];
    await Firestore.instance.document("Users/$username").get().then((onValue){
      if(onValue.exists){
        map.addAll(onValue.data['groups']);
        map.add({groupId : groupName});
        onValue.reference.updateData({'groups' : map});
      }
    });
  }
  
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
  final DocumentReference documentReference = Firestore.instance.document("Users/$username");
  
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
     return friendSuggestion;
    }

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
    userList.remove(username);
    });
    return userList.where((p)=>p.startsWith(s)).toList();// Used in case we want to return query beginning
    //return userList.where((p)=>p.compareTo(s)==0).toList(); //If exact match needed on query.
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
        onTap: () {
          Navigator.of(context).pop();
          saveGroupInfo(snapshot.data[index]);
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
        onTap: () async{
                  //Adding people to each other's friendlist if one selects the name of the user.
                   Navigator.of(context).pop();
                   await saveGroupInfo(snapshot.data[index]);
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