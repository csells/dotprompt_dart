// ignore_for_file: avoid_dynamic_calls, avoid_print

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
  if (expected.length != actual.length) {
    print(
      'Length mismatch at "$path": '
      'expected ${expected.length}, actual ${actual.length}',
    );
    print('Expected keys at "$path": ${expected.keys}');
    print('Actual keys at "$path": ${actual.keys}');
    return false;
  }

  for (final key in expected.keys) {
    final currentPath = path.isEmpty ? key : '$path.$key';

    if (!actual.containsKey(key)) {
      print('Missing key at "$currentPath"');
      return false;
    }

    final value1 = expected[key];
    final value2 = actual[key];

    if (value1 is Map<String, dynamic>) {
      if (!mapDeepEquals(value1, value2 as Map<String, dynamic>, currentPath)) {
        return false;
      }
    } else if (value1 is List) {
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
