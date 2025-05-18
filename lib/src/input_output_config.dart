import 'dart:developer' as dev;

import 'package:json_schema/json_schema.dart';

import 'pico_schema.dart' as pico;

/// Base class for configuration with schema handling.
abstract class BaseConfig {
  /// Creates a new instance of [BaseConfig].
  BaseConfig({Map<String, dynamic>? schema})
    : _schema =
          schema != null && schema.isNotEmpty ? _getJsonSchema(schema) : null;

  final JsonSchema? _schema;

  /// The JSON Schema for the configuration.
  JsonSchema? get schema => _schema;

  static JsonSchema? _getJsonSchema(Map<String, dynamic> schema) {
    final type = pico.PicoSchema.schemaType(schema);
    if (type == pico.SchemaType.unknown) {
      throw const FormatException(
        'Schema must be valid JSON Schema or PicoSchema',
      );
    }
    final map =
        type == pico.SchemaType.picoSchema
            ? pico.PicoSchema(schema).expand()
            : schema;
    print('DEBUG: Schema being passed to JsonSchema.create: $map');
    dev.log('Schema being passed to JsonSchema.create: $map');
    return JsonSchema.create(map);
  }
}

/// Configuration for input handling in a .prompt file.
class InputConfig extends BaseConfig {
  /// Creates a new instance of [InputConfig].
  InputConfig({super.schema, Map<String, dynamic>? defaults})
    : defaults = defaults ?? {};

  /// Default values for the input.
  final Map<String, dynamic> defaults;
}

/// Configuration for output handling in a .prompt file.
class OutputConfig extends BaseConfig {
  /// Creates a new instance of [OutputConfig].
  OutputConfig({super.schema, String? format}) : format = format ?? 'text';

  /// The format of the output (defaults to 'text').
  final String format;
}
