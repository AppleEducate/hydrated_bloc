import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Interface which `HydratedBlocDelegate` uses to persist and retrieve
/// state changes from the local device.
abstract class HydratedStorage {
  /// Returns value for key
  dynamic read(String key);

  /// Persists key value pair
  Future<void> write(String key, dynamic value);

  /// Clears all key value pairs from storage
  Future<void> clear();
}

/// Implementation of `HydratedStorage` which uses `PathProvider` and `dart.io`
/// to persist and retrieve state changes from the local device.
class HydratedBlocStorage implements HydratedStorage {
  static const String _hydratedBlocStorageName = '.hydrated_bloc.json';
  static HydratedBlocStorage _instance;
  Map<String, dynamic> _storage;
  File _file;

  /// Returns an instance of `HydratedBlocStorage`.
  static Future<HydratedBlocStorage> getInstance({bool testing = false}) async {
    if (_instance != null) {
      return _instance;
    }

    final Directory directory = await getDocumentDir(testing: testing);
    final File file = getFilePath(directory, testing: testing);
    Map<String, dynamic> storage = Map<String, dynamic>();

    if (await file.exists()) {
      try {
        storage =
            json.decode(await file.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        await file.delete();
      }
    }

    _instance = HydratedBlocStorage._(storage, file);
    return _instance;
  }

  HydratedBlocStorage._(this._storage, this._file);

  @override
  dynamic read(String key) {
    return _storage[key];
  }

  @override
  Future<void> write(String key, dynamic value) async {
    _storage[key] = value;
    await _file.writeAsString(json.encode(_storage));
    return _storage[key] = value;
  }

  @override
  Future<void> clear() async {
    _storage = Map<String, dynamic>();
    _instance = null;
    return await _file.exists() ? await _file.delete() : null;
  }

  static Future<Directory> getDocumentDir({bool testing = false}) async {
    if (!testing) {
      if (Platform.isMacOS || Platform.isLinux) {
        return Directory('${Platform.environment['HOME']}/.config');
      } else if (Platform.isWindows) {
        return Directory('${Platform.environment['UserProfile']}\\.config');
      }
    }
    return await getTemporaryDirectory();
  }

  static File getFilePath(Directory directory, {bool testing = false}) {
    if (testing) return File('./$_hydratedBlocStorageName');
    return File('${directory.path}/$_hydratedBlocStorageName');
  }
}
