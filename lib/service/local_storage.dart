import 'package:hive_flutter/hive_flutter.dart';

enum StorageKeys { posTerminalId, cpocTerminalId }

class LocalStorage {
  static Box<String>? _posTerminaLId;
  static Box<String>? _cpocTerminalId;
  static Box<String>? get posTerminalIdBox => _posTerminaLId;
  static Box<String>? get cpocTerminalIdBox => _cpocTerminalId;

  static Future<void> initialize() async {
    await Hive.initFlutter('ttp_example');
    await _openBoxes();
  }

  static Future<void> _openBoxes() async {
    _posTerminaLId = await Hive.openBox("posTerminalId");
    _cpocTerminalId = await Hive.openBox("cpocTerminalId");
  }
}
