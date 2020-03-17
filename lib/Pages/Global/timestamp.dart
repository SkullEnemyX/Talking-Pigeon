import 'package:intl/intl.dart';

class TimeStamp {
  static final TimeStamp _timeStamp = TimeStamp._internal();
  factory TimeStamp() {
    return _timeStamp;
  }
  TimeStamp._internal();

  String lastSeen(String status) {
    if (status.compareTo("online") == 0 ||
        status.compareTo("") == 0 ||
        status == null) {
      return status;
    } else {
      var now = DateTime.now();
      var date = DateTime.fromMillisecondsSinceEpoch(int.parse(status));
      var diff = now.difference(date);
      var formatHR = DateFormat("hh:mm a");
      var formatDAY = DateFormat("MMM dd, y");
      if (diff.inDays < 1 &&
          DateFormat("dd").format(now) == DateFormat("dd").format(date)) {
        return "last seen today at " + formatHR.format(date);
      } else if (diff.inDays == 1 ||
          int.parse(DateFormat("dd").format(date)) ==
              int.parse(DateFormat("dd").format(now)) - 1) {
        return "last seen yesterday at " + formatHR.format(date);
      }
      return "last seen on " + formatDAY.format(date);
    }
  }

  bool checkChangeInDate(int prevtimestamp, int curtimestamp) {
    DateTime prevDate = DateTime.fromMillisecondsSinceEpoch(prevtimestamp);
    DateTime curDate = DateTime.fromMillisecondsSinceEpoch(curtimestamp);
    DateFormat dateFormat = DateFormat("d");
    if (prevDate.difference(curDate).inDays >= 1 ||
        int.parse(dateFormat.format(prevDate)) !=
            int.parse(dateFormat.format(curDate))) {
      return true;
    }
    return false;
  }

  String timeOfTheDay(int hour) {
    DateTime now = DateTime.now();
    hour = int.parse(DateFormat('kk').format(now));

    if (hour >= 0 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    }
    return "Good Evening";
  }

  String lastMessageTimestamp(int timestamp) {
    var now = new DateTime.now();
    var format = new DateFormat('hh:mm a');
    var date = new DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 0 ||
        diff.inSeconds > 0 && diff.inMinutes == 0 ||
        diff.inMinutes > 0 && diff.inHours == 0 ||
        diff.inHours > 0 && diff.inDays == 0) {
      time = format.format(date);
      return time;
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = 'Yesterday';
        return time;
      }
    }
    format = DateFormat("dd/M/y");
    time = format.format(date);
    return time;
  }

  String currentMessageTimestamp(int timestamp) {
    var format = new DateFormat('HH:mm a');
    var date = new DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
    var time = '';
    format = DateFormat("hh:mm a");
    time = format.format(date);
    return time;
  }
}
