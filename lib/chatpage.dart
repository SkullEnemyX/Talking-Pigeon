import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
      snap = snapshotReturn();
    }

  @override
    void dispose() {
      // TODO: implement dispose
      super.dispose();
      textEditingController.dispose();
    }

  final TextEditingController textEditingController = new TextEditingController();
  var listMsg = [];
  String msg;
  final ScrollController listScrollController = new ScrollController();



  messageList(String msg){
    if(listMsg.length>=20)
    {
      listMsg.removeAt(0);
    }
    listMsg.add([msg,false,false]);
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
                                          .limit(30)
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
        title: new Text("${widget.frienduid}".toString().split(" ")[0],//Change Name to Friends name.
        style: TextStyle(fontSize: 23.0,color: widget.greet),),
        leading: new IconButton(
          icon: Icon(Icons.arrow_back,color: Color(0xFF27E9E1),),
          onPressed: (){
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
                  if(!snapshot.hasData) return CircularProgressIndicator();
                  if(snapshot.data.documents.length!=null)
                  {
                    return ListView.builder(
                      reverse: true,
                      itemCount: snapshot.data.documents.length,
                      controller: listScrollController,
                      itemBuilder: (context,i)
                      {
                       try{
                        DocumentSnapshot document = snapshot.data.documents[i];
                        //counter = counter + 1 ;
                        print(snapshot.data.documents.length);
                        //setState(() {});
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                                  new Presentmessage(message: document["content"],
                                  notme: document["isMe"].compareTo(widget.name)==0?false:true,
                                  delivered: listMsg[i][2],
                                  time: document["timestamp"],),
                            ],
                          );
                       }
                       catch(RangeError)
                    {
                      //querySnapShotCounter = querySnapShotCounter+1;
                      //i+=1;
                     throw(RangeError);

                    }
                        }
                    );
                  }
                  else
                  {
                    return Container();
                  }
                  if(snapshot.connectionState == ConnectionState.waiting)
                  {
                    return Center(child: SpinKitDoubleBounce(
                          size: 60.0,
                          color: Color(0xFF27E9E1),
                        ));
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
                  boxShadow: [
                    BoxShadow(
                    spreadRadius: 3.0,
                    color: widget.greet != Color(0xFF242424)?Colors.white54:Colors.grey.shade400
                  ),
                  BoxShadow(
                    spreadRadius: 3.0,
                    color: Colors.grey.shade600
                  ),
                  BoxShadow(
                    spreadRadius: 2.0,
                    color: Colors.grey.shade300
                  ),
                  BoxShadow(
                    spreadRadius: 1.0,
                    color: Colors.grey.shade200
                  ),
                  ]
                  
                ),
                child: new TextFormField(
                                      textAlign: TextAlign.start,
                                      decoration: new InputDecoration(
                                        filled: true,
                                        border: InputBorder.none,
                                        fillColor: Colors.transparent,
                                        hintText: "Type a message"
                                        ,suffixIcon: IconButton(
                                          icon: Icon(Icons.send,size: 25.0,),
                                          color: Colors.black,
                                          disabledColor: Colors.grey,
                                          onPressed: sendMessage,
                                        )
                                      ),
                                      //scrollPadding: EdgeInsets.all(20.0),
                                      controller: textEditingController,
                                      keyboardType: TextInputType.text,
                                      style: TextStyle(color: widget.background == Color(0xFF242424)?widget.background:widget.greet,fontSize: 18.0,),
                                      onSaved: (val)=> msg = val,
                                    ),
              ),
            ),
          ],
        ),
        // child: new Column(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: <Widget>[
            
        //   // new TextFormField(
        //   //   keyboardType: TextInputType.text,
        //   // ) 
        //   ],
        // ),
      ),

    );
  }

  void sendMessage() {
  if(textEditingController.value.text!="")
  {
  messageList(textEditingController.value.text);
  //Refreshing widget when new message is sent or appears.
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
  listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);

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
    //final String message = "Hello my name is Skull and I am awesome";
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
                      width: message.split(" ").length <= 9?null:width,
                      margin: const EdgeInsets.all(10.0),
                      padding: const EdgeInsets.all(8.0),
                      //color: Colors.red,
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
                    padding: EdgeInsets.only(right: 48.0,bottom: 5.0),
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
 if(int.parse(value.substring(0,2))>=12)
 {
   return(int.parse(value.substring(0,2))==12?
   (int.parse(value.substring(0,2))).toString() +"${value.substring(2,5)}" +" PM":
   (int.parse(value.substring(0,2))-12).toString() +"${value.substring(2,5)}" +" PM");
 }
 else
 {
   return(int.parse(value.substring(0,2))==00?
   (int.parse(value.substring(0,2))+12).toString() +"${value.substring(2,5)}" +" AM":
   (int.parse(value.substring(0,2))).toString() +"${value.substring(2,5)}" +" AM");
 }
}
