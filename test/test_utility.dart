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
