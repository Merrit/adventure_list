import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:helpers/helpers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Interfaces with the host OS to store & retrieve data from disk.
class StorageRepository {
  /// This class is a singleton.
  /// Singleton instance of the service.
  static late StorageRepository instance;

  /// Private singleton constructor.
  StorageRepository._singleton();

  /// Initialize the storage access and [instance].
  /// Needs to be initialized only once, in the `main()` function.
  static Future<StorageRepository> initialize() async {
    /// On desktop platforms initialize to a specific directory.
    if (platformIsDesktop()) {
      final dir = await getApplicationSupportDirectory();
      // Defaults to ~/.local/share/adventure_list/storage
      Hive.init('${dir.path}/storage');
    } else {
      // On mobile and web initialize to default location.
      await Hive.initFlutter();
    }

    instance = StorageRepository._singleton();
    return instance;
  }

  /// A generic storage pool, anything large should make its own box.
  static const String _generalBox = 'general';

  /// Persist a value to local disk storage.
  Future<void> saveValue({
    required String key,
    required dynamic value,
    String? storageArea,
  }) async {
    final Box box = await _getBox(storageArea);
    await box.put(key, value);
  }

  /// Save all values to disk.
  Future<void> saveStorageAreaValues({
    required String storageArea,
    required Map<dynamic, dynamic> entries,
  }) async {
    final Box box = await _getBox(storageArea);
    await box.putAll(entries);
  }

  /// Get a value from local disk storage.
  ///
  /// If the [key] doesn't exist, `null` is returned.
  Future<dynamic> getValue(String key, {String? storageArea}) async {
    final Box box = await _getBox(storageArea);
    return box.get(key);
  }

  /// Get all values associated with a particlar storage.
  Future<Iterable<dynamic>> getStorageAreaValues(String storageArea) async {
    final Box box = await _getBox(storageArea);
    return box.values;
  }

  /// Delete a key from storage.
  Future<void> deleteValue(String key, {String? storageArea}) async {
    final Box box = await _getBox(storageArea);
    await box.delete(key);
  }

  /// Get a Hive storage box, either the one associated with
  /// [storageAreaName], or the general storage box.
  Future<Box> _getBox(String? storageAreaName) async {
    try {
      return await Hive.openBox(storageAreaName ?? _generalBox);
    } on Exception catch (e) {
      debugPrint('Unable to access storage; is another app instance '
          'already running? \n$e');
      exit(1);
    }
  }
}
