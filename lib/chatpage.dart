import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final Color greet;
  final Color background;
  final String name;
  final String frienduid;

  ChatPage({Key key, this.name,this.greet,this.background,this.frienduid}) : super(key: key);

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
    }

  @override
    void dispose() {
      super.dispose();
      textEditingController.dispose();
    }

  final TextEditingController textEditingController = new TextEditingController();
  List listMsg = [];
  String msg;
  final ScrollController listScrollController = new ScrollController();

  messageList(String msg,bool notme,String timestamp){
    if(listMsg.length>=20)
    {
      listMsg.removeAt(0);
    }
    listMsg.add([msg,notme,timestamp]);
    return listMsg;
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
  
  Stream<QuerySnapshot> snapshotReturn(){
    var snap = Firestore.instance
                                          .collection('messages')
                                          .document(returnGroupId(widget.name, widget.frienduid))
                                          .collection(returnGroupId(widget.name, widget.frienduid))
                                          .orderBy('timestamp', descending: true)
                                          .limit(50)
                                          .snapshots();
    return snap;
  }

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      home: Scaffold(
        appBar: new AppBar(
          elevation: 0.0,
          backgroundColor: widget.background,
          centerTitle: true,
          title: new Text("${widget.frienduid}".toString().split(" ")[0],//Change Name to Friends name.
          style: TextStyle(fontSize: 23.0,color: widget.greet),),
          leading: new IconButton(
            icon: Icon(Icons.arrow_back,color: Color(0xFF27E9E1),),
            onPressed: () async{
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
                child:StreamBuilder(
                  stream: snap,
                  builder: (context,snapshot)
                  {
                    listMsg = [];
                    if(!snapshot.hasData) return CircularProgressIndicator();
                    else{
                      List<DocumentSnapshot> document = snapshot.data.documents;
                      print(document.length);
                      for(int i=0;i<document.length;i++)
                      {
                        listMsg.add([document[i]["content"],
                        document[i]["isMe"].compareTo(widget.name)==0?false:true,
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
                                        textCapitalization: TextCapitalization.sentences,
                                        style: TextStyle(color: widget.background == Color(0xFF242424)?widget.background:widget.greet,fontSize: 18.0,),
                                        onSaved: (val)=> msg = val,
                                      ),
                ),
              ),
            ],
          ),
        ),

      ),
    );
  }

  void sendMessage() {
  if(textEditingController.value.text!="")
  {
  setState(() {
   messageList(textEditingController.value.text,false,time());
   listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.elasticIn);
  //Refreshing widget when new message is sent or appears. 
  });
  var documentReference = Firestore.instance
  .collection('messages')
  .document(returnGroupId(widget.name, widget.frienduid))
  .collection(returnGroupId(widget.name, widget.frienduid))
  .document(DateTime.now().millisecondsSinceEpoch.toString());

  Firestore.instance.runTransaction((transaction) async {
  await transaction.set(
  documentReference,
  {
  'timestamp': time(),
  'content': textEditingController.value.text,
  'isMe' : widget.name
  },
  );
  }).whenComplete((){textEditingController.clear();
  setState(() {
  });
  });

  }
  }
}

class Presentmessage extends StatelessWidget {
  final String message;
  final bool notme;
  final bool delivered;
  final String time;
   Presentmessage({
    Key key,
    this.delivered,
    this.message,
    this.notme,
    this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Bubble(message: message,notMe: notme,delivered: delivered,time: time,);
  }
}

class Bubble extends StatelessWidget{

  Bubble({this.message,this.notMe,this.delivered,this.time});
  final bool delivered;
  final bool notMe;
  final String message;
  final String time;
  
  @override
  Widget build(BuildContext context) {
    final bg = notMe ? Colors.white : Color(0xFF27E9E1).withOpacity(0.8);
    final align = notMe ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final icon = delivered ? Icons.done_all : Icons.done;
    final double width = MediaQuery.of(context).size.width*0.75;
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
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Container(
                      margin: const EdgeInsets.all(10.0),
                      padding: const EdgeInsets.all(8.0),
                      //color: Colors.red,
                      constraints: BoxConstraints(
                        maxWidth: width,
                        minWidth: 110.0
                      ),
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
                    padding: EdgeInsets.only(right: 48.0,bottom: 12.0),
                    child: Text(message,style: TextStyle(fontSize: 16.0),),
                  ),
                  Positioned(
                    bottom: 0.0,
                    right: 0.0,
                    child: Row(
                      children: <Widget>[
                        Text(time,
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 8.0,
                            )),
                        SizedBox(width: 3.0),
                        Icon(
                          icon,
                          size: 12.0,
                          color: Colors.black38,
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
String time() {
 String value = DateTime.now().toString().split(" ")[1].substring(0,5);
 String fullDate = DateTime.now().toString().substring(0,10);
 print(fullDate);
 if(int.parse(value.substring(0,2))>=12)
 {
   return(int.parse(value.substring(0,2))==12?
   (int.parse(value.substring(0,2))).toString() +"${value.substring(2,5)}" +" PM " + fullDate:
   (int.parse(value.substring(0,2))-12).toString() +"${value.substring(2,5)}" +" PM " + fullDate);
 }
 else
 {
   return(int.parse(value.substring(0,2))==00?
   (int.parse(value.substring(0,2))+12).toString() +"${value.substring(2,5)}" +" AM " + fullDate:
   (int.parse(value.substring(0,2))).toString() +"${value.substring(2,5)}" +" AM " + fullDate);
 }
}