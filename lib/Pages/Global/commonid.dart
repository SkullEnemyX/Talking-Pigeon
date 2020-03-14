class CommonID {
  static final CommonID _timeStamp = CommonID._internal();
  factory CommonID() {
    return _timeStamp;
  }
  CommonID._internal();

  String singleChatConversationID(String myid, String friendid) {
    if (myid.hashCode >= friendid.hashCode) {
      return (myid.hashCode.toString() + friendid.hashCode.toString());
    } else {
      return (friendid.hashCode.toString() + myid.hashCode.toString());
    }
  }

  String groupChatConversationID(String adminID) {
    //To generate a unique ID everytime a group is created, I am currently using the logic of appending the unique_username
    // with the timestamp the group is created in order to create a unique ID for a group.
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return adminID.hashCode.toString() + timestamp;
  }
}
