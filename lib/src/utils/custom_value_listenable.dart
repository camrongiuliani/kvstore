import 'package:flutter/foundation.dart';

abstract class CustomValueListenable<T> extends ValueListenable<T> {

  @override
  void addListener(VoidCallback listener);

  @override
  void removeListener(VoidCallback listener);

  Stream<dynamic> watch();

}