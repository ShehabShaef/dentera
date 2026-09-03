import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dentera/core/logging/app_logger.dart';

/// Configures the local SQLite testing environment using Foreign Function Interface (FFI).
///
/// **Why FFI is required for desktop-level testing:**
/// Standard Flutter SQLite plugins (`sqflite`) rely on platform-native channels (Java/Kotlin
/// on Android, Objective-C/Swift on iOS). When executing unit and widget tests locally
/// via `flutter test` on host machines (Windows, macOS, Linux), those mobile operating system
/// channels are absent. Running tests without FFI would normally require booting a slow
/// mobile emulator or connecting a physical device.
///
/// `sqflite_common_ffi` bridges Dart directly to the host machine's SQLite C dynamic library
/// via Dart FFI (`dart:ffi`). Initializing [sqfliteFfiInit] and routing [databaseFactory]
/// to [databaseFactoryFfi] allows all subsequent database calls (connections, schema creation,
/// transactions, constraints) to execute natively in-process at high speed.
///
/// In addition, this setup binds a mock handler for `path_provider` to ensure filesystem
/// path resolutions (such as `getApplicationDocumentsDirectory`) resolve cleanly to the
/// system temporary directory during headless desktop test executions.
void setupDatabaseTests() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI bindings for desktop test runner.
  sqfliteFfiInit();

  // Route database operations through the FFI factory instead of mobile platform channels.
  databaseFactory = databaseFactoryFfi;

  // Mock path_provider method channel so getApplicationDocumentsDirectory()
  // resolves to a valid local test temporary directory on host test runners.
  final tempDirPath = Directory.systemTemp.createTempSync('dentera_test_').path;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return tempDirPath;
  });

  AppLogger.debug('[TestSetup] sqflite_common_ffi databaseFactory successfully initialized.');
}
