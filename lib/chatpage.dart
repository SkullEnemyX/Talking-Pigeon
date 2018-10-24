import 'package:flutter/material.dart';

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

  final TextEditingController textEditingController = new TextEditingController();
  var listMsg = [];
  String msg;



  messageList(String msg){
    if(listMsg.length>=20)
    {
      listMsg.removeAt(0);
    }
    listMsg.add([msg,false,false]);
    return listMsg;
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
            Expanded(
              child:ListView.builder(
                  shrinkWrap: true,
                  itemCount: listMsg.length,
                  itemBuilder: (context,index)
                  {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                            new Presentmessage(message:listMsg[index][0],notme: listMsg[index][1],delivered: listMsg[index][2],),
                      ],
                    );
                    }
                ),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
                          child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: widget.greet != Color(0xFF242424)?widget.greet:Colors.grey.shade200,
                  borderRadius: new BorderRadius.circular(20.0),
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
                                          onPressed: (){
                                            if(textEditingController.value.text!="")
                                            messageList(textEditingController.value.text);
                                            setState(() {}); //Refreshing widget when new message is sent or appears.
                                            textEditingController.clear();},
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
}

class Presentmessage extends StatelessWidget {
  final String message;
  final bool notme;
  final bool delivered;
   Presentmessage({
    Key key,
    this.delivered,
    this.message,
    this.notme
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Bubble(message: message,notMe: notme,delivered: delivered,);
  }
}

class Bubble extends StatelessWidget{

  Bubble({this.message,this.notMe,this.delivered});
  final bool delivered;
  final bool notMe;
  final String message;
  
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
                        Text("11.00",
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 10.0,
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