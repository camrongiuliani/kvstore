import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:key_value_store/key_value_store.dart';
import 'package:key_value_store/src/utils/key_value_pair.dart';

typedef _ValueReader = dynamic Function( String );
typedef _StreamReader = Stream<KeyValuePair> Function();


class MultiValueListenable extends CustomValueListenable<Map<String, dynamic>> {

  final List<String> _keys;
  final _StreamReader _getStream;
  final _ValueReader _readValue;

  final List<VoidCallback> _listeners = [];

  final Map<String, dynamic> _values;

  StreamController? _watchStreamController;
  StreamSubscription? _hiveSubscription;

  MultiValueListenable( this._keys, this._readValue, this._getStream ) :
        _values = Map.fromIterable( _keys.map((e) => e), value: ( el ) => null );

  @override
  Map<String, dynamic> get value => _values;

  @override
  Stream<dynamic> watch() {

    void _watchListener() => print('Watching Keys');

    _watchStreamController ??= StreamController(
      onListen: () {

        for ( var entry in _values.entries ) {
          var value = entry.value;

          if ( value == null ) {
            var storedVal =  _readValue( entry.key );

            if ( storedVal != null ) {
              _values[ entry.key ] = storedVal;
            }
          }
        }

        _watchStreamController?.sink.add( value );

        addListener( _watchListener );
      },
      onCancel: () =>  removeListener( _watchListener ),
    );
    return _watchStreamController!.stream;

  }

  @override
  void addListener(VoidCallback listener) {

    if (_listeners.isEmpty) {
      _hiveSubscription =  _getStream().listen((event) {
        if ( _keys.contains( event.key ) ) {
          _values[ event.key ] = event.value;

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
      _hiveSubscription?.cancel();
      _hiveSubscription = null;
      _watchStreamController?.close();
      _watchStreamController = null;
    }
  }
}
