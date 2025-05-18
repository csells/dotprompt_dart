import 'dart:developer' as dev;

/// A class for handling PicoSchema expansion and validation.
class PicoSchema {
  /// Creates a new instance of [PicoSchema].
  /// Throws [FormatException] if the schema is not a valid PicoSchema.
  PicoSchema(this.schema) {
    if (!isPicoSchema(schema)) {
      throw const FormatException('Schema is not a valid pico schema');
    }
  }

  /// The schema to expand.
  final Map<String, dynamic> schema;

  /// Checks if the schema contains PicoSchema features.
  static bool isPicoSchema(Map<String, dynamic> schema) {
    // Check properties for PicoSchema features
    if (schema.containsKey('properties')) {
      final properties = schema['properties'] as Map<String, dynamic>;
      for (final entry in properties.entries) {
        // If any property key contains PicoSchema features, it's PicoSchema shorthand
        if (entry.key.contains('?') || entry.key.contains('(')) return true;
        // If any property value is a string, it's PicoSchema shorthand
        if (entry.value is String) return true;
        // Recursively check nested properties
        if (entry.value is Map<String, dynamic>) {
          if (isPicoSchema(entry.value as Map<String, dynamic>)) return true;
        }
      }
    }

    // Check for wildcard fields
    if (schema.containsKey('(*)')) return true;

    // Check for wildcard in additionalProperties
    if (schema.containsKey('additionalProperties')) {
      final additionalProperties = schema['additionalProperties'];
      if (additionalProperties is String) return true;
      if (additionalProperties is Map<String, dynamic>) {
        return isPicoSchema(additionalProperties);
      }
    }

    // Check items for PicoSchema features
    if (schema.containsKey('items')) {
      final items = schema['items'];
      if (items is String) return true;
      if (items is Map<String, dynamic>) {
        return isPicoSchema(items);
      }
    }

    return false;
  }

  /// Returns a valid JSON Schema map, expanding PicoSchema if needed.
  static Map<String, dynamic> _getJsonSchema(Map<String, dynamic> map) =>
      isPicoSchema(map) ? PicoSchema(map).expand() : map;

  /// Expands PicoSchema shorthand into valid JSON Schema.
  /// If the input is already valid JSON Schema, it is passed through unchanged.
  Map<String, dynamic> expand() {
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
            // Check for invalid wildcard field syntax in nested map
            final nestedMap = Map<String, dynamic>.from(value);
            for (final nestedKey in nestedMap.keys) {
              if (nestedKey.trim().startsWith('(*') &&
                  nestedKey.trim() != '(*)') {
                throw FormatException(
                  'Invalid wildcard field syntax: $nestedKey',
                );
              }
            }
            wildcardSchema = _getJsonSchema(nestedMap);
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
          var nested = _getJsonSchema(Map<String, dynamic>.from(value));
          // If the nested schema contains only a (*) key (and maybe
          // description), transform it
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
              wildcardSchema = _getJsonSchema(
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
            if (type == 'any') {
              // Special case: array of any type
              formattedProperties[normalizedKey] = {
                'type': 'array',
                'items': {},
                if (arrayDesc != null) 'description': arrayDesc,
              };
              return;
            }
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
        formatted['items'] = _getJsonSchema(
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
        formatted['additionalProperties'] = _getJsonSchema(
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
    return formatted;
  }
}
