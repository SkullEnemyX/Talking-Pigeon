import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LifeCycleManager extends StatefulWidget {
  final Widget child;
  final String username;
  LifeCycleManager({Key key, this.child, this.username}) : super(key: key);

  @override
  _LifeCycleManagerState createState() => _LifeCycleManagerState();
}

class _LifeCycleManagerState extends State<LifeCycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (widget.username != "") {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        await Firestore.instance
            .collection("Users")
            .document(widget.username)
            .updateData(
                {"status": DateTime.now().millisecondsSinceEpoch.toString()});
      } else if (state == AppLifecycleState.resumed) {
        await Firestore.instance
            .collection("Users")
            .document(widget.username)
            .updateData({"status": "online"});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
