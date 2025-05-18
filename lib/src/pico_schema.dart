import 'dart:developer' as dev;

/// The type of schema being used.
enum SchemaType {
  /// Standard JSON Schema format
  jsonSchema,

  /// Picoschema format
  picoSchema,

  /// Unknown or invalid schema format
  unknown,
}

/// A class for handling PicoSchema expansion and validation.
class PicoSchema {
  /// Creates a new instance of [PicoSchema].
  /// Throws [FormatException] if the schema is not a valid PicoSchema.
  PicoSchema(this.schema) {
    dev.log('DEBUG: PicoSchema constructor received schema: \\$schema');
    if (schemaType(schema) != SchemaType.picoSchema) {
      throw const FormatException('Schema is not a valid pico schema');
    }

    // final parser = PicoschemaParser();
    // final result = parser.parse(jsonEncode(schema));
    // if (result.isSuccess) {
    //   final root = result.value as ObjectField;
    //   dev.log(root.pretty());
    // } else {
    //   dev.log(result.message);
    // }
  }

  /// The schema to expand.
  final Map<String, dynamic> schema;

  /// Determines the type of schema: JSON Schema, Picoschema, or unknown.
  static SchemaType schemaType(Map<String, dynamic> schema) {
    // If there's a type property at the top level, it's JSON Schema
    // and ALL nested properties must follow JSON Schema format
    if (schema.containsKey('type')) {
      // Validate that there are no PicoSchema features anywhere in the schema
      bool hasPicoFeatures(dynamic value) {
        if (value is Map<String, dynamic>) {
          // Check for PicoSchema indicators in keys
          for (final key in value.keys) {
            if (key.contains('?') || key.contains('(') || key == '(*)') {
              return true;
            }
          }
          // Check values recursively
          for (final val in value.values) {
            if (hasPicoFeatures(val)) return true;
          }
        } else if (value is String) {
          // In JSON Schema context, only check for comma-separated descriptions
          // as those are definitely PicoSchema syntax
          return value.contains(',');
        }
        return false;
      }

      if (hasPicoFeatures(schema)) {
        throw const FormatException(
          'Mixed schema types not allowed. Schema must be either pure JSON '
          'Schema or pure PicoSchema',
        );
      }
      return SchemaType.jsonSchema;
    }

    // Check for PicoSchema features
    if (schema.containsKey('properties')) {
      final properties = schema['properties'] as Map<String, dynamic>;
      for (final entry in properties.entries) {
        // If any property key contains PicoSchema features, it's PicoSchema
        if (entry.key.contains('?') || entry.key.contains('(')) {
          return SchemaType.picoSchema;
        }

        // If any property value is a string with a comma (type, description) or
        // a simple type name
        if (entry.value is String) {
          final str = entry.value as String;
          if (str.contains(',') ||
              [
                'string',
                'number',
                'integer',
                'boolean',
                'null',
                'object',
                'array',
                'any',
              ].contains(str.trim())) {
            return SchemaType.picoSchema;
          }
        }
      }
    }

    // Check for wildcard fields
    if (schema.containsKey('(*)')) {
      return SchemaType.picoSchema;
    }

    // If we haven't found any clear indicators, return unknown
    return SchemaType.unknown;
  }

  /// Returns a valid JSON Schema map, expanding PicoSchema if needed.
  static Map<String, dynamic> _getJsonSchema(Map<String, dynamic> map) {
    dev.log('DEBUG: _getJsonSchema received map: \\$map');
    final type = schemaType(map);
    if (type == SchemaType.picoSchema) {
      return PicoSchema(map).expand();
    } else if (type == SchemaType.jsonSchema) {
      return map; // Pass through pure JSON Schema unchanged
    }
    return map;
  }

  /// Expands PicoSchema shorthand into valid JSON Schema.
  /// If the input is already valid JSON Schema, it is passed through unchanged.
  Map<String, dynamic> expand() {
    dev.log('DEBUG: Input schema to expand: \\$schema');
    dev.log('Input schema: $schema'); // Debug log

    // Recursively check every map for invalid wildcard field syntax
    void checkInvalidWildcardSyntax(dynamic map) {
      if (map is Map) {
        final dartMap = map as Map<String, dynamic>;
        for (final key in dartMap.keys) {
          if (key.trim().startsWith('(*') && key.trim() != '(*)') {
            throw FormatException('Invalid wildcard field syntax: $key');
          }
        }
        dartMap.values.forEach(checkInvalidWildcardSyntax);
      }
    }

    checkInvalidWildcardSyntax(schema);

    // This is PicoSchema shorthand - expand it
    final formatted = Map<String, dynamic>.from(schema);

    // Ensure root object has type: object
    if (!formatted.containsKey('type')) {
      formatted['type'] = 'object';
    }

    // Handle root-level wildcard first
    if (formatted.containsKey('(*)')) {
      final value = formatted['(*)'];
      if (value is String) {
        final parts = value.split(',');
        final type = parts[0].trim();
        final description = parts.length > 1 ? parts[1].trim() : null;

        if (type == 'any') {
          formatted['additionalProperties'] = true;
        } else {
          formatted['additionalProperties'] = {
            'type': type,
            if (description != null) 'description': description,
          };
        }
      } else if (value is Map) {
        final schema = PicoSchema({'properties': value}).expand();
        formatted['additionalProperties'] = schema;
      }
      formatted.remove('(*)');
    }

    // If we have properties, expand them
    if (formatted.containsKey('properties')) {
      final properties = formatted['properties'] as Map<String, dynamic>;
      final formattedProperties = <String, dynamic>{};

      // Handle root-level wildcard in properties
      if (properties.containsKey('(*)')) {
        final value = properties['(*)'];
        if (value is String) {
          final parts = value.split(',');
          final type = parts[0].trim();
          final description = parts.length > 1 ? parts[1].trim() : null;

          if (type == 'any') {
            formatted['additionalProperties'] = true;
          } else {
            formatted['additionalProperties'] = {
              'type': type,
              if (description != null) 'description': description,
            };
          }
        } else if (value is Map) {
          final schema = PicoSchema({'properties': value}).expand();
          formatted['additionalProperties'] = schema;
        }
        properties.remove('(*)');
      }

      for (final entry in properties.entries) {
        final key = entry.key;
        final value = entry.value;
        dev.log('Processing property: $key = $value'); // Debug log

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
              '[31m${parenMatch.group(2)}[0m',
            );
          }
          normalizedKey = parenMatch.group(1)!.trim();
          picoType = parenMatch.group(2);
          picoDescription = parenMatch.group(3)?.trim();
        } else {
          normalizedKey = keyWithoutOptional.trim();
        }

        // Handle nested wildcards
        if (value is Map && value.containsKey('(*)')) {
          final wildcardValue = value['(*)'];
          if (wildcardValue is String) {
            final parts = wildcardValue.split(',');
            final type = parts[0].trim();
            final description = parts.length > 1 ? parts[1].trim() : null;

            if (type == 'any') {
              formattedProperties[normalizedKey] = {
                'type': 'object',
                'additionalProperties': true,
                if (description != null) 'description': description,
              };
            } else {
              formattedProperties[normalizedKey] = {
                'type': 'object',
                'additionalProperties': {
                  'type': type,
                  if (description != null) 'description': description,
                },
              };
            }
            continue;
          } else if (wildcardValue is Map) {
            final schema = PicoSchema({'properties': wildcardValue}).expand();
            formattedProperties[normalizedKey] = {
              'type': 'object',
              'additionalProperties': schema,
            };
            continue;
          }
        }

        // ARRAY HANDLING: handle at the top level, not inside if (value is Map)
        if (picoType == 'array') {
          final arraySchema = <String, dynamic>{
            'type': 'array',
            if (picoDescription != null) 'description': picoDescription,
          };

          if (value is String) {
            // handle shorthand
            final parts = value.split(',');
            final itemType = parts[0].trim();
            final itemDescription = parts.length > 1 ? parts[1].trim() : null;

            if (itemType == 'any') {
              arraySchema['items'] = <String, dynamic>{};
            } else {
              arraySchema['items'] = <String, dynamic>{
                'type': itemType,
                if (itemDescription != null) 'description': itemDescription,
              };
            }
          } else if (value is Map<String, dynamic>) {
            // handle nested object - maintain PicoSchema syntax
            final itemSchema = PicoSchema({'properties': value}).expand();
            arraySchema['items'] = itemSchema;
          } else {
            arraySchema['items'] = value;
          }

          if (optional) {
            arraySchema['type'] = <String>['array', 'null'];
          }

          formattedProperties[normalizedKey] = arraySchema;
          dev.log(
            'DEBUG: Assigned array property for $normalizedKey: \\$arraySchema',
          );
          continue;
        }

        if (value is Map) {
          // Check for invalid wildcard field syntax in all nested property maps
          if (value.containsKey('properties')) {
            final nestedProperties =
                value['properties'] as Map<String, dynamic>;
            for (final nestedKey in nestedProperties.keys) {
              if (nestedKey.trim().startsWith('(*') &&
                  nestedKey.trim() != '(*)') {
                throw FormatException(
                  'Invalid wildcard field syntax: $nestedKey',
                );
              }
            }
          }
          // Recursively format nested properties and ensure wildcard expansion
          final nested = Map<String, dynamic>.from(value);
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
          } else if (!nested.containsKey('type')) {
            // If no type is specified, default to object
            nested['type'] = 'object';
          }

          // Add description from PicoSchema if present
          if (picoDescription != null) {
            nested['description'] = picoDescription;
          }

          // Convert nested properties to proper JSON Schema format
          if (!nested.containsKey('properties')) {
            final nestedProperties = <String, dynamic>{};
            for (final entry in nested.entries) {
              if (entry.key != 'type' && entry.key != 'description') {
                final optional = entry.key.endsWith('?');
                final normalizedKey =
                    optional
                        ? entry.key.substring(0, entry.key.length - 1)
                        : entry.key;

                if (entry.value is String) {
                  final parts = entry.value.toString().split(',');
                  final type = parts[0].trim();
                  final description = parts.length > 1 ? parts[1].trim() : null;
                  nestedProperties[normalizedKey] = {
                    'type': optional ? [type, 'null'] : type,
                    if (description != null) 'description': description,
                  };
                } else if (entry.value is Map) {
                  final nestedValue =
                      PicoSchema({'properties': entry.value}).expand();
                  if (optional) {
                    nestedValue['type'] = ['object', 'null'];
                  }
                  nestedProperties[normalizedKey] = nestedValue;
                }
              }
            }
            if (nestedProperties.isNotEmpty) {
              nested['properties'] = nestedProperties;
            }
          }

          formattedProperties[normalizedKey] = nested;
          continue;
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
          continue;
        } else if (value is String) {
          // Handle simple type definitions like "string, description"
          final parts = value.split(',').map((s) => s.trim()).toList();
          final type = parts[0].trim();
          final description =
              parts.length > 1 ? parts.sublist(1).join(',').trim() : null;

          // Use PicoSchema features if present
          if (picoType == 'object') {
            final objectDesc = picoDescription ?? description;
            if (optional) {
              formattedProperties[normalizedKey] = {
                'type': ['object', 'null'],
                if (objectDesc != null) 'description': objectDesc,
              };
            } else {
              formattedProperties[normalizedKey] = {
                'type': 'object',
                if (objectDesc != null) 'description': objectDesc,
              };
            }
            continue;
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
              continue;
            } else {
              // Invalid enum syntax
              throw const FormatException('Invalid enum syntax in PicoSchema');
            }
          }

          // Handle special case: 'any'
          if (type == 'any') {
            if (optional) {
              formattedProperties[normalizedKey] = {
                'type': ['object', 'null'],
                'additionalProperties': true,
                if (description != null) 'description': description,
              };
            } else {
              formattedProperties[normalizedKey] = {
                'type': 'object',
                'additionalProperties': true,
                if (description != null) 'description': description,
              };
            }
            continue;
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
            continue;
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
          continue;
        } else {
          // If value is not a String, Map, or (for enums) List, it's invalid
          throw const FormatException('Invalid PicoSchema property value');
        }
      }

      formatted['properties'] = formattedProperties;
      if (formatted.containsKey('additionalProperties')) {
        // For 'any', set additionalProperties to true (bool)
        if (formatted['additionalProperties'] is Map<String, dynamic>) {
          final ws = formatted['additionalProperties'] as Map<String, dynamic>;
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
        } else if (formatted['additionalProperties'] is bool) {
          // Keep as is
        }
        // If this object is only a wildcard, ensure type: object and remove (*)
        if (!formatted.containsKey('type')) {
          formatted['type'] = 'object';
        }
      }
    }

    // Handle arrays
    if (formatted.containsKey('items')) {
      if (formatted['items'] is Map) {
        formatted['items'] = _getJsonSchema(
          Map<String, dynamic>.from(formatted['items']),
        );
      } else if (formatted['items'] is String) {
        // Handle simple type string for items
        formatted['items'] = {'type': formatted['items']};
      }
    }

    // After formatting properties, check required fields
    if (formatted.containsKey('required') &&
        formatted.containsKey('properties')) {
      final requiredFields = List<String>.from(formatted['required'] as List);
      final propertyKeys =
          (formatted['properties'] as Map<String, dynamic>).keys.toSet();
      final missing =
          requiredFields.where((f) => !propertyKeys.contains(f)).toList();
      if (missing.isNotEmpty) {
        throw FormatException(
          'Required field(s) missing from properties: ${missing.join(', ')}',
        );
      }
    }

    dev.log('Final expanded schema: $formatted'); // Debug log
    dev.log('DEBUG: Final expanded schema: \\$formatted');
    if (formatted.containsKey('items')) {
      dev.log('DEBUG: Final items property: \\${formatted['items']}');
    }
    return formatted;
  }
}
