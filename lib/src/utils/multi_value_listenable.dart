import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:abstract_kv_store/abstract_kv_store.dart';
import 'package:abstract_kv_store/src/utils/key_value_pair.dart';

typedef _ValueReader = dynamic Function( String );
typedef _StreamReader = Stream<KeyValuePair> Function();

class MultiValueListenable extends CustomValueListenable<Map<String, dynamic>> {

  final List<String> _keys;
  final _StreamReader _getStream;
  final _ValueReader _readValue;

  final List<VoidCallback> _listeners = [];

  final Map<String, dynamic> _values;

  StreamController? _outputStreamController;
  StreamSubscription? _inputStreamSubscription;


  MultiValueListenable( this._keys, this._readValue, this._getStream ) :
        _values = _keys.isEmpty ? {} : Map.fromIterable( _keys.map((e) => e), value: ( el ) => null );

  @override
  Map<String, dynamic> get value => _values;

  @override
  Stream<dynamic> watch() {

    void _watchListener() => print('Watching Keys');

    _outputStreamController ??= StreamController(
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

        _outputStreamController?.sink.add( value );

        addListener( _watchListener );
      },
      onCancel: () =>  removeListener( _watchListener ),
    );
    return _outputStreamController!.stream;

  }

  @override
  void addListener(VoidCallback listener) {
    if (_listeners.isEmpty) {
      _inputStreamSubscription =  _getStream().listen((event) {
        if ( _keys.isEmpty ) {
          for (var listener in _listeners) {
            listener();
          }
        } else if ( _keys.contains( event.key ) ) {
          _values[ event.key ] = event.value;

          _outputStreamController?.sink.add( _values );

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
