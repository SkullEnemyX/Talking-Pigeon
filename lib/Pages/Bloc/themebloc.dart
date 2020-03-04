import 'dart:async';

class Bloc {
  final _themeController = StreamController<bool>();
  Function(bool) get changeTheme => _themeController.sink.add;
  get darkThemeEnabled => _themeController.stream;
  get closeController => _themeController.close();
}

final bloc = Bloc();
