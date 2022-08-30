

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:key_value_store/key_value_store.dart';
import 'package:key_value_store/src/utils/key_value_pair.dart';
import 'package:key_value_store/src/utils/multi_value_listenable.dart';
import 'package:key_value_store/src/utils/single_value_listenable.dart';

class StoreHiveImpl extends KVStore {

  static const String _boxId = "KVBox";

  final String name;

  Box? _box;

  StoreHiveImpl( this.name, { bool persist = false } ) : super( persist );

  @override
  bool get isOpen => _box?.isOpen == true;

  @override
  Future<void> init({ List<dynamic> typeAdapters = const [] }) async {
    await Hive.initFlutter();

    for (var adapter in typeAdapters) {
      if ( ! Hive.isAdapterRegistered( adapter.typeId ) ) {
        Hive.registerAdapter( adapter );
      }
    }
  }

  @override
  Future<KVStore?> open() async {

    if ( _box != null && _box!.isOpen ) {
      return Future.value( this );
    }

    try {

      _box = await Hive.openBox( '${_boxId}_$name' );

      return this;

    } catch(e) {

      if ( kDebugMode ) {
        print( 'KVS: Failed to open box ($name)' );
      } else {
        throw Exception( 'KVS: Failed to open box ($name)' );
      }

    }
    return null;
  }

  @override
  Future delete( String key ) async {

    assert( ! locked );

    if ( locked ) {
      if (kDebugMode) {
        print( 'Attempted to delete a value for $key from a locked box: ($name)' );
      }
      return;
    }

    await open();
    return await _box?.delete( key );
  }

  @override
  Future<void> set( String key, dynamic value ) async {

    await open();

    bool readOnly = locked && _box?.containsKey( key ) == true;

    assert( ! readOnly, 'Attempted to set an already existing value for $key in locked box: ($name)' );

    if ( readOnly ) {
      return;
    }

    return await _box?.put( key, value );
  }

  @override
  Future<T?> get<T>( String key, { dynamic fallback } ) async {
    await open();
    return await _box?.get( key, defaultValue: fallback ) as T?;
  }

  @override
  Future<void> dump({ bool debugAllowDumpLocked = false }) async {
    bool debugDump = kDebugMode && debugAllowDumpLocked;

    await open();

    assert( _box != null, 'Tried to dump box but box was null.' );
    assert( ! locked || debugDump, 'Attempted to dump a locked box: ($name).' );

    if ( _box != null && ( ! locked || debugDump ) ) {
      await Hive.deleteBoxFromDisk( _box!.name );
    }
  }

  @override
  CustomValueListenable listenable( keyOrKeys ) {
    assert( _box != null && _box!.isOpen );
    assert( keyOrKeys is List<String> || keyOrKeys is String );

    var transformer = StreamTransformer.fromHandlers(
      handleData: ( BoxEvent data, EventSink<KeyValuePair> sink ) => sink.add( KeyValuePair( data.key, data.value ) ),
    );

    if ( keyOrKeys is String ) {
      return SingleValueListenable(
        keyOrKeys,
        _box!.get,
        ( key ) => _box!.watch( key:  key ).transform( transformer ),
      );
    } else {
      return MultiValueListenable(
        keyOrKeys,
        _box!.get,
        () => _box!.watch().transform( transformer ),
      );
    }
  }

  @override
  Stream<dynamic> watch( keyOrKeys ) => listenable( keyOrKeys ).watch();

}
