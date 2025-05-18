// ignore_for_file: avoid_dynamic_calls, avoid_print

import 'dart:convert';

import 'package:json_schema/json_schema.dart';

/// Extension on JsonSchema for test utilities
extension JsonSchemaTestExtension on JsonSchema {
  /// Returns the type or typeList as a displayable string or list of strings.
  String get typeName {
    // If we have a typeList, use that first
    final typeList = this.typeList;
    final type = typeList?.firstOrNull;
    if (typeList != null && typeList.isNotEmpty) {
      final buffer = StringBuffer();
      for (final type in typeList) {
        if (buffer.isNotEmpty) buffer.write(', ');
        buffer.write(type.toString());
      }
      return buffer.toString();
    }

    // Fall back to type if no typeList
    if (type != null) return type.toString();

    // If we have properties but no type, it's an object
    if (properties.isNotEmpty) return 'object';

    // If we have items but no type, it's an array
    if (items != null) return 'array';

    // If the schema is an empty object (e.g., items: {}), return 'any'
    if (properties.isEmpty && items == null) return 'any';

    return 'none';
  }

  // Returns the additionalProperties schema if present and a map, else null.
  JsonSchema? get additionalProperties {
    final map = schemaMap;
    if (map == null) return null;
    final ap = map['additionalProperties'];
    if (ap is Map<String, dynamic>) {
      return JsonSchema.create(ap);
    }
    return null;
  }
}

// Helper function to compare two objects deeply for equality
bool mapDeepEquals(
  Map<String, dynamic> expected,
  Map<String, dynamic> actual, [
  String path = '',
]) {
  // Normalize both objects through JSON serialization
  final normalizedExpected = jsonDecode(jsonEncode(expected));
  final normalizedActual = jsonDecode(jsonEncode(actual));

  return _mapDeepEqualsImpl(
    normalizedExpected as Map<String, dynamic>,
    normalizedActual as Map<String, dynamic>,
    path,
  );
}

bool _mapDeepEqualsImpl(
  Map<String, dynamic> expected,
  Map<String, dynamic> actual, [
  String path = '',
]) {
  // Special case: if both maps are empty, they're equal
  if (expected.isEmpty && actual.isEmpty) {
    return true;
  }

  if (expected.length != actual.length) {
    print(
      'Length mismatch at "$path": '
      'expected ${expected.length}, actual ${actual.length}',
    );
    print('Expected keys at "$path": ${expected.keys}');
    print('Actual keys at "$path": ${actual.keys}');
    return false;
  }

  // Sort the keys to ensure consistent comparison order
  final expectedKeys = expected.keys.toList()..sort();
  final actualKeys = actual.keys.toList()..sort();

  for (var i = 0; i < expectedKeys.length; i++) {
    final key = expectedKeys[i];
    final actualKey = actualKeys[i];

    if (key != actualKey) {
      print(
        'Key order mismatch at "$path": expected "$key", actual "$actualKey"',
      );
      return false;
    }

    final currentPath = path.isEmpty ? key : '$path.$key';
    final value1 = expected[key];
    final value2 = actual[key];

    if (value1 is Map<String, dynamic>) {
      if (value2 is! Map<String, dynamic>) {
        print(
          'Type mismatch at "$currentPath": '
          'expected Map, actual ${value2.runtimeType}',
        );
        return false;
      }
      // Special case: if both maps are empty, they're equal
      if (value1.isEmpty && value2.isEmpty) {
        continue;
      }
      if (!_mapDeepEqualsImpl(value1, value2, currentPath)) {
        return false;
      }
    } else if (value1 is List) {
      if (value2 is! List) {
        print(
          'Type mismatch at "$currentPath": '
          'expected List, actual ${value2.runtimeType}',
        );
        return false;
      }
      if (value1.length != value2.length) {
        print(
          'List length mismatch at "$currentPath": '
          'expected "${value1.length}", actual "${value2.length}"',
        );
        return false;
      }
      for (var i = 0; i < value1.length; i++) {
        if (value1[i] != value2[i]) {
          print(
            'List mismatch at "$currentPath[$i]": '
            'expected "${value1[i]}", actual "${value2[i]}"',
          );
          return false;
        }
      }
    } else if (value1 != value2) {
      print(
        'Value mismatch at "$currentPath": '
        'expected "$value1", actual "$value2"',
      );
      return false;
    }
  }

  return true;
}
