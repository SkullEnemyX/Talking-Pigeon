import 'dart:async';

import 'package:flutter/cupertino.dart';

class Bloc {
  final _themeController = StreamController<bool>();
  Function(bool) get changeTheme => _themeController.sink.add;
  get darkThemeEnabled => _themeController.stream;
  get closeController => _themeController.close();
}

class ColorBloc {
  final _themeControllerColor = StreamController<Color>();
  Function(Color) get changeColorTheme => _themeControllerColor.sink.add;
  get colorTheme => _themeControllerColor.stream;
  get closeColorController => _themeControllerColor.close();
}

final bloc = Bloc();
final colorBloc = ColorBloc();
