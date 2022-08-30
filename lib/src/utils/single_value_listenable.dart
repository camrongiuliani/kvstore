import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:abstract_kv_store/src/utils/custom_value_listenable.dart';
import 'package:abstract_kv_store/src/utils/key_value_pair.dart';

typedef _ValueReader = dynamic Function( String );
typedef _StreamReader = Stream<KeyValuePair> Function( String );

class SingleValueListenable extends CustomValueListenable<dynamic> {

  final String _key;
  final _StreamReader _getStream;
  final _ValueReader _readValue;

  final List<VoidCallback> _listeners = [];

  dynamic _value;

  StreamController? _outputStreamController;
  StreamSubscription? _inputStreamSubscription;

  SingleValueListenable( this._key, this._readValue, this._getStream );

  @override
  dynamic get value => _value;

  @override
  Stream<dynamic> watch() {
    if ( _outputStreamController == null ) {

      _watchListener() => null;

      _outputStreamController = StreamController(
        onListen: () {

          if ( value == null ) {
            var storedVal = _readValue( _key );
            if ( storedVal != null ) {
              _outputStreamController?.sink.add(storedVal);
            }
          }

          addListener( _watchListener );
        },
        onCancel: () =>  removeListener( _watchListener ),
      );
    }

    return _outputStreamController!.stream;

  }

  @override
  void addListener(VoidCallback listener) {
    if (_listeners.isEmpty) {
      _inputStreamSubscription = _getStream( _key ).listen((event) {
        if ( _value != event.value ) {
          _value = event.value;

          _outputStreamController?.sink.add( _value );

          for (var listener in _listeners) {
            listener();
          }
        }
      });
    }

    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);

    if (_listeners.isEmpty) {
      _inputStreamSubscription?.cancel();
      _inputStreamSubscription = null;
      _outputStreamController?.close();
      _outputStreamController = null;
    }
  }
}
