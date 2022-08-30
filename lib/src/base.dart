import 'package:flutter/foundation.dart';
import 'package:key_value_store/key_value_store.dart';

abstract class KVStore {

  bool locked;

  KVStore(this.locked);

  bool get isOpen;

  bool initialized = false;

  Future<KVStore?> open();

  Future<void> init({ List<dynamic> typeAdapters = const [] });

  Future<T?> get<T>( String key, { dynamic fallback } );

  Future<void> dump({ bool debugAllowDumpLocked = false });

  Future delete( String key );

  Future<void> set( String key, dynamic value );

  Stream<dynamic> watch( dynamic keyOrKeys );

  ValueListenable listenable( dynamic keyOrKeys );

  static KVStore build( String name, { KVProvider storageProvider = KVProvider.hive, bool mutable = true } )  {
    switch( storageProvider ) {
      default:
        return StoreHiveImpl( name, persist: ! mutable );
    }
  }

}