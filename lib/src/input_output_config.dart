import 'package:json_schema/json_schema.dart';

import 'pico_schema.dart';
import 'utility.dart';

/// Base class for configuration with schema handling.
abstract class BaseConfig {
  /// Creates a new instance of [BaseConfig].
  BaseConfig({Map<String, dynamic>? schema})
    : _schema =
          schema != null && schema.isNotEmpty
              ? JsonSchema.create(() {
                final dartSchema = yamlToMap(schema) as Map<String, dynamic>;
                return PicoSchema.isPicoSchema(dartSchema)
                    ? PicoSchema(dartSchema).expand()
                    : dartSchema;
              }())
              : null;

  final JsonSchema? _schema;

  /// The JSON Schema for the configuration.
  JsonSchema? get schema => _schema;
}

/// Configuration for input handling in a .prompt file.
class InputConfig extends BaseConfig {
  /// Creates a new instance of [InputConfig].
  InputConfig({super.schema, Map<String, dynamic>? defaultValues})
    : defaultValues = defaultValues ?? {};

  /// Default values for the input.
  final Map<String, dynamic> defaultValues;
}

/// Configuration for output handling in a .prompt file.
class OutputConfig extends BaseConfig {
  /// Creates a new instance of [OutputConfig].
  OutputConfig({super.schema, String? format}) : format = format ?? 'text';

  /// The format of the output (defaults to 'text').
  final String format;
}
