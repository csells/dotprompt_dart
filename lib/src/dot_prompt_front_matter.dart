import 'dart:convert';
import 'dart:developer' as dev;

import 'package:json_schema/json_schema.dart';
import 'package:yaml/yaml.dart';

import 'utility.dart';

/// Configuration for input handling in a .prompt file.
class InputConfig {
  /// Creates a new instance of [InputConfig].
  InputConfig({Map<String, dynamic>? schema, Map<String, dynamic>? default_})
    : _schema =
          schema != null && schema.isNotEmpty
              ? JsonSchema.create(_expandPicoSchema(schema))
              : null,
      default_ = default_ ?? {};

  final JsonSchema? _schema;

  /// The JSON Schema for the input.
  JsonSchema? get schema => _schema;

  /// Default values for the input.
  final Map<String, dynamic> default_;

  /// Expands PicoSchema shorthand into valid JSON Schema.
  /// If the input is already valid JSON Schema, it is passed through unchanged.
  static Map<String, dynamic> _expandPicoSchema(Map<String, dynamic> schema) {
    dev.log('Input schema: $schema'); // Debug log

    // Check if this is already valid JSON Schema
    var isAlreadyJsonSchema = true;

    // Check properties for PicoSchema features
    if (schema.containsKey('properties')) {
      final properties = schema['properties'] as Map<String, dynamic>;
      for (final entry in properties.entries) {
        // If any property value is a string, it's PicoSchema shorthand
        if (entry.value is String) {
          isAlreadyJsonSchema = false;
          break;
        }
        // If any property key contains ? or (, it's PicoSchema shorthand
        if (entry.key.contains('?') || entry.key.contains('(')) {
          isAlreadyJsonSchema = false;
          break;
        }
      }
    }

    if (isAlreadyJsonSchema) {
      dev.log('Passing through standard JSON Schema: $schema'); // Debug log
      return schema; // Pass through standard JSON Schema unchanged
    }

    // This is PicoSchema shorthand - expand it
    final formatted = Map<String, dynamic>.from(schema);

    // Ensure type is a string
    if (formatted.containsKey('type')) {
      if (formatted['type'] is List) {
        // For type lists, we'll use typeList instead
        formatted['typeList'] = (formatted['type'] as List).cast<String>();
        // Keep the first type as the primary type
        formatted['type'] = (formatted['type'] as List).first.toString();
      } else {
        // For single types, keep as is - JsonSchema.create will convert to
        // SchemaType
        formatted['type'] = formatted['type'].toString();
      }
    }

    // Format properties
    if (formatted.containsKey('properties')) {
      final properties = formatted['properties'] as Map<String, dynamic>;
      final formattedProperties = <String, dynamic>{};
      Map<String, dynamic>? wildcardSchema;

      properties.forEach((key, value) {
        dev.log('Processing property: $key = $value'); // Debug log
        // Handle wildcard fields: (*)
        if (key.trim() == '(*)') {
          // Expand the wildcard schema
          if (value is String) {
            // e.g. (*): string
            final parts = value.split(',');
            final type = parts[0].trim();
            final description = parts.length > 1 ? parts[1].trim() : null;
            if (type == 'any') {
              wildcardSchema = {};
              if (description != null) {
                wildcardSchema?['description'] = description;
              }
            } else {
              wildcardSchema = {
                'type': type,
                if (description != null) 'description': description,
              };
            }
            dev.log('Created wildcard schema: $wildcardSchema'); // Debug log
          } else if (value is Map) {
            wildcardSchema = _expandPicoSchema(
              Map<String, dynamic>.from(value),
            );
          }
          // Do not add to formattedProperties
          return;
        }

        // Parse PicoSchema features from the original key
        final optional = key.endsWith('?');
        final keyWithoutOptional =
            optional ? key.substring(0, key.length - 1) : key;
        final parenMatch = RegExp(
          r'^(.*?)\(([^,)]+)(?:,\s*(.*?))?\)',
        ).firstMatch(keyWithoutOptional);
        String normalizedKey;
        String? picoType;
        String? picoDescription;
        if (parenMatch != null) {
          // Check for invalid parenthetical types
          if (!['array', 'object', 'enum'].contains(parenMatch.group(2))) {
            throw FormatException(
              'Invalid parenthetical type in PicoSchema: '
              '${parenMatch.group(2)}',
            );
          }
          normalizedKey = parenMatch.group(1)!.trim();
          picoType = parenMatch.group(2);
          picoDescription = parenMatch.group(3)?.trim();
        } else {
          normalizedKey = keyWithoutOptional.trim();
        }

        if (value is Map) {
          // Recursively format nested properties and ensure wildcard expansion
          var nested = _expandPicoSchema(Map<String, dynamic>.from(value));
          // If the nested schema contains only a (*) key (and maybe description), transform it
          if (nested.keys.where((k) => k != 'description').length == 1 &&
              nested.containsKey('(*)')) {
            final wildcard = nested.remove('(*)');
            Map<String, dynamic>? wildcardSchema;
            if (wildcard is String) {
              final parts = wildcard.split(',');
              final type = parts[0].trim();
              final description = parts.length > 1 ? parts[1].trim() : null;
              if (type == 'any') {
                wildcardSchema = {};
                if (description != null) {
                  wildcardSchema['description'] = description;
                }
              } else {
                wildcardSchema = {
                  'type': type,
                  if (description != null) 'description': description,
                };
              }
            } else if (wildcard is Map) {
              wildcardSchema = _expandPicoSchema(
                Map<String, dynamic>.from(wildcard),
              );
            }
            if (wildcardSchema != null) {
              if (wildcardSchema.isEmpty) {
                nested = {
                  'type': 'object',
                  'additionalProperties': true,
                  if (nested['description'] != null)
                    'description': nested['description'],
                };
              } else {
                if (!wildcardSchema.containsKey('type')) {
                  wildcardSchema['type'] = 'object';
                }
                nested = {
                  'type': 'object',
                  'additionalProperties': wildcardSchema,
                  if (nested['description'] != null)
                    'description': nested['description'],
                };
              }
            }
          }
          // Always preserve description if present
          if (picoDescription != null && !nested.containsKey('description')) {
            nested['description'] = picoDescription;
          }
          if (picoType == 'array') {
            // This is an array of objects (or other types)
            final arrayDesc = picoDescription;
            formattedProperties[normalizedKey] = {
              'type': 'array',
              'items': nested,
              if (arrayDesc != null) 'description': arrayDesc,
            };
            return;
          }
          if (optional) {
            // For optional nested objects/arrays, ensure type/typeList is correct
            if (nested.containsKey('type')) {
              final t = nested['type'];
              if (nested['type'] is List) {
                // Already a list, add null if not present
                final tl = List.from(nested['type']);
                if (!tl.contains('null')) tl.add('null');
                nested['type'] = tl;
              } else {
                nested['type'] = [t, 'null'];
              }
            } else {
              // If no type is specified, default to object
              nested['type'] = ['object', 'null'];
            }
          }
          formattedProperties[normalizedKey] = nested;
          return;
        } else if (value is List && picoType == 'enum') {
          // Handle enum values as YAML list
          final enumDesc = picoDescription;
          if (optional) {
            formattedProperties[normalizedKey] = {
              'type': ['string', 'null'],
              'enum': value,
              if (enumDesc != null) 'description': enumDesc,
            };
          } else {
            formattedProperties[normalizedKey] = {
              'type': 'string',
              'enum': value,
              if (enumDesc != null) 'description': enumDesc,
            };
          }
        } else if (value is String) {
          // Handle simple type definitions like "string, description"
          final parts = value.split(',');
          final type = parts[0].trim();
          final description = parts.length > 1 ? parts[1].trim() : null;

          // Use PicoSchema features if present
          if (picoType == 'array') {
            final arrayDesc = picoDescription ?? description;
            final itemType = type;
            final itemsSchema = {'type': itemType};
            if (optional) {
              formattedProperties[normalizedKey] = {
                'type': 'array',
                'typeList': ['array', 'null'],
                'items': itemsSchema,
                if (arrayDesc != null) 'description': arrayDesc,
              };
            } else {
              formattedProperties[normalizedKey] = {
                'type': 'array',
                'items': itemsSchema,
                if (arrayDesc != null) 'description': arrayDesc,
              };
            }
            return;
          }
          if (picoType == 'object') {
            final objectDesc = picoDescription ?? description;
            if (optional) {
              formattedProperties[normalizedKey] = {
                'type': 'object',
                'typeList': ['object', 'null'],
                if (objectDesc != null) 'description': objectDesc,
              };
            } else {
              formattedProperties[normalizedKey] = {
                'type': 'object',
                if (objectDesc != null) 'description': objectDesc,
              };
            }
            return;
          }
          if (picoType == 'enum') {
            final enumDesc = picoDescription ?? description;
            if (type.startsWith('[') && type.endsWith(']')) {
              final enumValues =
                  type
                      .substring(1, type.length - 1)
                      .split(',')
                      .map((e) => e.trim())
                      .toList();
              if (optional) {
                formattedProperties[normalizedKey] = {
                  'type': ['string', 'null'],
                  'enum': enumValues,
                  if (enumDesc != null) 'description': enumDesc,
                };
              } else {
                formattedProperties[normalizedKey] = {
                  'type': 'string',
                  'enum': enumValues,
                  if (enumDesc != null) 'description': enumDesc,
                };
              }
              return;
            } else {
              // Invalid enum syntax
              throw const FormatException('Invalid enum syntax in PicoSchema');
            }
          }

          // Handle special case: 'any'
          if (type == 'any') {
            final anyTypes = [
              'string',
              'number',
              'integer',
              'boolean',
              'null',
              'object',
              'array',
            ];
            if (optional) {
              formattedProperties[normalizedKey] = {
                'type': 'object',
                'typeList': anyTypes,
                if (description != null) 'description': description,
              };
            } else {
              formattedProperties[normalizedKey] = {
                'type': 'object', // Default to object for 'any'
                if (description != null) 'description': description,
              };
            }
            return;
          }

          // Handle enum values (not using (enum) syntax)
          if (type.startsWith('[') && type.endsWith(']')) {
            final enumValues =
                type
                    .substring(1, type.length - 1)
                    .split(',')
                    .map((e) => e.trim())
                    .toList();
            if (optional) {
              formattedProperties[normalizedKey] = {
                'type': ['string', 'null'],
                'enum': enumValues,
                if (description != null) 'description': description,
              };
            } else {
              formattedProperties[normalizedKey] = {
                'type': 'string',
                'enum': enumValues,
                if (description != null) 'description': description,
              };
            }
            return;
          }

          // Default case: simple type
          // Validate supported scalar types
          final supportedTypes = {
            'string',
            'number',
            'integer',
            'boolean',
            'null',
            'object',
            'array',
            'any',
          };
          if (!supportedTypes.contains(type)) {
            throw FormatException('Unsupported scalar type: $type');
          }
          if (optional) {
            formattedProperties[normalizedKey] = {
              'type': [type, 'null'],
              if (description != null) 'description': description,
            };
          } else {
            formattedProperties[normalizedKey] = {
              'type': type,
              if (description != null) 'description': description,
            };
          }
        } else {
          // If value is not a String, Map, or (for enums) List, it's invalid
          throw const FormatException('Invalid PicoSchema property value');
        }
      });

      formatted['properties'] = formattedProperties;
      if (wildcardSchema != null) {
        // For 'any', set additionalProperties to true (bool)
        if (wildcardSchema is Map<String, dynamic>) {
          final ws = wildcardSchema!;
          if (ws.isEmpty) {
            formatted['additionalProperties'] = true;
            dev.log('Set additionalProperties: true (for any)'); // Debug log
          } else {
            if (!ws.containsKey('type')) {
              ws['type'] = 'object';
            }
            formatted['additionalProperties'] = ws;
            dev.log(
              'Set additionalProperties: ${formatted['additionalProperties']}',
            ); // Debug log
          }
        } else if (wildcardSchema is bool) {
          formatted['additionalProperties'] = wildcardSchema;
        }
        // If this object is only a wildcard, ensure type: object and remove (*)
        if (!formatted.containsKey('type')) {
          formatted['type'] = 'object';
        }
        // Remove any lingering (*) key
        formatted.remove('(*)');
      }
    }

    // Handle arrays
    if (formatted.containsKey('items')) {
      if (formatted['items'] is Map) {
        formatted['items'] = _expandPicoSchema(
          Map<String, dynamic>.from(formatted['items']),
        );
      } else if (formatted['items'] is String) {
        // Handle simple type string for items
        formatted['items'] = {'type': formatted['items']};
      }
    }

    // Handle additional properties
    if (formatted.containsKey('additionalProperties')) {
      if (formatted['additionalProperties'] is Map) {
        formatted['additionalProperties'] = _expandPicoSchema(
          Map<String, dynamic>.from(formatted['additionalProperties']),
        );
      } else if (formatted['additionalProperties'] is String) {
        final type = formatted['additionalProperties'] as String;
        formatted['additionalProperties'] = {
          'type': type == 'any' ? 'object' : type,
          if (type == 'any')
            'typeList': [
              'string',
              'number',
              'integer',
              'boolean',
              'null',
              'object',
              'array',
            ],
        };
      }
    }

    dev.log('Final expanded schema: $formatted'); // Debug log
    return formatted;
  }

  static Map<String, dynamic> _prepareSchemaForJsonSchema(
    Map<String, dynamic> schema,
  ) {
    // If additionalProperties is a map, ensure it's a valid schema map
    if (schema.containsKey('additionalProperties') &&
        schema['additionalProperties'] is Map<String, dynamic>) {
      // Recursively prepare additionalProperties
      schema['additionalProperties'] = _prepareSchemaForJsonSchema(
        Map<String, dynamic>.from(schema['additionalProperties']),
      );
    }
    // If properties exist, recursively prepare them
    if (schema.containsKey('properties')) {
      final props = schema['properties'] as Map<String, dynamic>;
      schema['properties'] = props.map((k, v) {
        if (v is Map<String, dynamic>) {
          return MapEntry(k, _prepareSchemaForJsonSchema(v));
        }
        return MapEntry(k, v);
      });
    }
    // If items exist and is a map, recursively prepare
    if (schema.containsKey('items') &&
        schema['items'] is Map<String, dynamic>) {
      schema['items'] = _prepareSchemaForJsonSchema(
        Map<String, dynamic>.from(schema['items']),
      );
    }
    return schema;
  }
}

/// Configuration for output handling in a .prompt file.
class OutputConfig {
  /// Creates a new instance of [OutputConfig].
  OutputConfig({Map<String, dynamic>? schema, String? format})
    : _schema =
          schema != null && schema.isNotEmpty
              ? JsonSchema.create(InputConfig._expandPicoSchema(schema))
              : null,
      format = format ?? 'text';

  final JsonSchema? _schema;

  /// The JSON Schema for the output.
  JsonSchema? get schema => _schema;

  /// The format of the output (defaults to 'text').
  final String format;
}

/// Represents the properties parsed from a .prompt file's front matter.
class DotPromptFrontMatter {
  /// Creates a new instance of [DotPromptFrontMatter].
  DotPromptFrontMatter({
    this.name,
    this.variant,
    this.model,
    this.tools,
    Map<String, dynamic>? config,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? ext,
  }) : config = config ?? {},
       input = InputConfig(
         schema: input?['schema'] as Map<String, dynamic>?,
         default_: input?['default'] as Map<String, dynamic>?,
       ),
       output = OutputConfig(
         schema: output?['schema'] as Map<String, dynamic>?,
         format: output?['format'] as String?,
       ),
       metadata = metadata ?? {},
       ext = ext ?? {};

  /// Creates metadata from a YAML map.
  factory DotPromptFrontMatter.fromMap(Map<String, dynamic> map) {
    // Convert any YamlMap values to regular Maps
    final convertedMap = yamlToMap(map) as Map<String, dynamic>;

    // Extract namespaced fields
    final ext = <String, dynamic>{};
    final data = Map<String, dynamic>.from(convertedMap);
    data.removeWhere((key, value) {
      if (key.contains('.')) {
        final parts = key.split('.');
        var current = ext;
        for (var i = 0; i < parts.length - 1; i++) {
          current[parts[i]] = current[parts[i]] ?? <String, dynamic>{};
          current = current[parts[i]];
        }
        // Recursively convert value for ext
        if (value is Map || value is YamlMap) {
          current[parts.last] = yamlToMap(value);
        } else if (value is List || value is YamlList) {
          current[parts.last] = yamlToList(value);
        } else {
          current[parts.last] = value;
        }
        return true;
      }
      return false;
    });

    // Strictly enforce the spec: only allow standard fields and namespaced
    // fields
    final standardFields = {
      'name',
      'variant',
      'model',
      'tools',
      'config',
      'input',
      'output',
      'metadata',
    };
    final nonStandardFields =
        data.keys.where((key) => !standardFields.contains(key)).toList();
    if (nonStandardFields.isNotEmpty) {
      throw FormatException(
        'Non-standard fields must be namespaced: '
        "'${nonStandardFields.join(', ')}'",
      );
    }

    Map<String, dynamic> ensureMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return Map<String, dynamic>.fromEntries(
          value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
        );
      }
      throw const FormatException(
        'input/output must be a map/object if present',
      );
    }

    final input = ensureMap(data['input']);
    final output = ensureMap(data['output']);

    return DotPromptFrontMatter(
      name: data['name'] as String?,
      variant: data['variant'] as String?,
      model: data['model'] as String?,
      tools: (data['tools'] as List?)?.cast<String>(),
      config: ensureMap(data['config']),
      input: input,
      output: output,
      metadata: ensureMap(data['metadata']),
      ext: ext,
    );
  }

  /// The name of the prompt.
  final String? name;

  /// The variant name for the prompt.
  final String? variant;

  /// The name of the model to use.
  final String? model;

  /// Names of tools to allow use of in this prompt.
  final List<String>? tools;

  /// Configuration to be passed to the model implementation.
  final Map<String, dynamic> config;

  /// Input configuration including defaults and schema.
  final InputConfig input;

  /// Output configuration including format and schema.
  final OutputConfig output;

  /// Arbitrary metadata to be used by code, tools, and libraries.
  final Map<String, dynamic> metadata;

  /// Extensions and namespaced fields.
  final Map<String, dynamic> ext;

  /// Gets a value from the metadata by key.
  dynamic operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'variant':
        return variant;
      case 'model':
        return model;
      case 'tools':
        return tools;
      case 'config':
        return config;
      case 'input':
        return input;
      case 'output':
        return output;
      case 'metadata':
        return metadata;
      default:
        return null;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    const encoder = JsonEncoder.withIndent('  ');

    if (name != null) buffer.writeln('name: $name');
    if (variant != null) buffer.writeln('variant: $variant');
    if (model != null) buffer.writeln('model: $model');
    if (tools != null && tools!.isNotEmpty) {
      buffer.writeln('tools: [${tools!.join(', ')}]');
    }

    if (config.isNotEmpty) buffer.writeln('config: ${encoder.convert(config)}');
    if (input.schema != null || input.default_.isNotEmpty) {
      buffer.writeln(
        // ignore: lines_longer_than_80_chars
        'input: ${encoder.convert({if (input.schema != null) 'schema': input.schema, if (input.default_.isNotEmpty) 'default': input.default_})}',
      );
    }
    if (output.schema != null || output.format != 'text') {
      buffer.writeln(
        // ignore: lines_longer_than_80_chars
        'output: ${encoder.convert({if (output.schema != null) 'schema': output.schema, if (output.format != 'text') 'format': output.format})}',
      );
    }
    if (metadata.isNotEmpty) {
      buffer.writeln('metadata: ${encoder.convert(metadata)}');
    }
    if (ext.isNotEmpty) buffer.writeln('extensions: ${encoder.convert(ext)}');

    return buffer.toString();
  }
}
