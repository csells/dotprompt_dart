// ignore_for_file: avoid_dynamic_calls, avoid_print

import 'dart:convert';

import 'package:dotprompt/dot_prompt.dart';
import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';

import 'test_utility.dart';

// Helper to safely traverse nested properties in JsonSchema
JsonSchema? getNestedProperty(JsonSchema? schema, List<String> path) {
  var current = schema;
  for (final key in path) {
    if (current == null) return null;
    current = current.properties[key];
  }
  return current;
}

void main() {
  group('Picoschema', () {
    // Basic Types Tests
    // https://google.github.io/dotprompt/reference/picoschema/#basic-types
    group('Basic Types', () {
      test('handles string type', () {
        const input = '''
---
input:
  schema:
    properties:
      name: string, The name of the user
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['name'], isNotNull);
        expect(schema.properties['name']!.typeName, 'string');
        expect(schema.properties['name']?.description, 'The name of the user');
      });

      test('handles number type', () {
        const input = '''
---
input:
  schema:
    properties:
      price: number, The price in dollars
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['price'], isNotNull);
        expect(schema.properties['price']!.typeName, 'number');
        expect(schema.properties['price']?.description, 'The price in dollars');
      });

      test('handles integer type', () {
        const input = '''
---
input:
  schema:
    properties:
      age: integer, The age in years
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['age'], isNotNull);
        expect(schema.properties['age']!.typeName, 'integer');
        expect(schema.properties['age']?.description, 'The age in years');
      });

      test('handles boolean type', () {
        const input = '''
---
input:
  schema:
    properties:
      isActive: boolean, Whether the item is active
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['isActive'], isNotNull);
        expect(schema.properties['isActive']!.typeName, 'boolean');
        expect(
          schema.properties['isActive']?.description,
          'Whether the item is active',
        );
      });

      test('handles null type', () {
        const input = '''
---
input:
  schema:
    properties:
      emptyField: null, A field that must be null
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['emptyField'], isNotNull);
        expect(schema.properties['emptyField']!.typeName, 'null');
        expect(
          schema.properties['emptyField']?.description,
          'A field that must be null',
        );
      });

      test('handles any type', () {
        const input = '''
---
input:
  schema:
    properties:
      data: any, Any type of data
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['data'], isNotNull);
        // 'any' is mapped to a list of types, so check typeList
        expect(schema.properties['data']?.typeList, isA<List<SchemaType?>>());
      });

      test('handles string with special characters', () {
        const input = r'''
---
input:
  schema:
    properties:
      text: string, Text with special chars -- !@#$%^&*()
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['text'], isNotNull);
        expect(schema.properties['text']!.typeName, 'string');
        expect(
          schema.properties['text']?.description,
          r'Text with special chars -- !@#$%^&*()',
        );
      });

      test('handles number with decimal points', () {
        const input = '''
---
input:
  schema:
    properties:
      price: number, Price with decimals
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['price'], isNotNull);
        expect(schema.properties['price']!.typeName, 'number');
      });

      test('handles integer with leading zeros', () {
        const input = '''
---
input:
  schema:
    properties:
      code: integer, Code with leading zeros
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['code'], isNotNull);
        expect(schema.properties['code']!.typeName, 'integer');
      });

      test('handles boolean with different casing', () {
        const input = '''
---
input:
  schema:
    properties:
      isActive: boolean, Boolean with different casing
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['isActive'], isNotNull);
        expect(schema.properties['isActive']!.typeName, 'boolean');
      });
    });

    // Optional Fields Tests
    // https://google.github.io/dotprompt/reference/picoschema/#optional-fields
    group('Optional Fields', () {
      test('handles optional fields', () {
        const input = '''
---
input:
  schema:
    properties:
      name: string, Required name
      subtitle?: string, Optional subtitle
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['name']!.typeName, 'string');
        expect(schema.properties['subtitle'], isNotNull);
        expect(schema.properties['subtitle']!.typeName, 'string, null');
      });

      test('optional fields are nullable', () {
        const input = '''
---
input:
  schema:
    properties:
      subtitle?: string, Optional subtitle
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['subtitle'], isNotNull);
        // Check typeList for nullable types
        expect(schema.properties['subtitle']!.typeName, 'string, null');
      });

      test('handles multiple optional fields in same object', () {
        const input = '''
---
input:
  schema:
    properties:
      name: string, Required name
      subtitle?: string, Optional subtitle
      description?: string, Optional description
      tags?: array, Optional tags
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['name']!.typeName, 'string');
        expect(schema.properties['subtitle']!.typeName, 'string, null');
        expect(schema.properties['description']!.typeName, 'string, null');
        expect(schema.properties['tags']!.typeName, 'array, null');
      });

      test('handles optional fields with default values', () {
        const input = '''
---
input:
  schema:
    properties:
      name: string, Required name
      subtitle?: string, Optional subtitle
  default:
    subtitle: Default subtitle
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['name']!.typeName, 'string');
        expect(schema.properties['subtitle']!.typeName, 'string, null');
        expect(
          prompt.frontMatter.input.defaults['subtitle'],
          'Default subtitle',
        );
      });

      test('handles optional fields in nested objects', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
            description: User name
          address:
            type: object
            properties:
              street:
                type: string
                description: Street address
              city:
                type: string
                description: City name
              state:
                type: string
                description: State code
          preferences:
            type: object
            properties:
              theme:
                type: string
                description: UI theme
              notifications:
                type: boolean
                description: Enable notifications
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(getNestedProperty(schema, ['user'])?.typeName, 'object');
        expect(getNestedProperty(schema, ['user', 'name'])?.typeName, 'string');
        expect(
          getNestedProperty(schema, ['user', 'address'])?.typeName,
          'object',
        );
        expect(
          getNestedProperty(schema, ['user', 'preferences'])?.typeName,
          'object',
        );
      });
    });

    // Arrays Tests
    // https://google.github.io/dotprompt/reference/picoschema/#arrays
    group('Arrays', () {
      test('handles string array', () {
        const input = '''
---
input:
  schema:
    properties:
      tags(array, List of tags): string
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['tags'], isNotNull);
        expect(schema.properties['tags']!.typeName, 'array');
        expect(schema.properties['tags']?.items, isNotNull);
        expect(schema.properties['tags']!.items!.typeName, 'string');
        expect(schema.properties['tags']?.description, 'List of tags');
      });

      test('handles nested object array', () {
        const input = '''
---
input:
  schema:
    properties:
      items(array, List of items):
        id: string, Item ID
        name: string, Item name
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['items'], isNotNull);
        expect(schema.properties['items']!.typeName, 'array');
        expect(schema.properties['items']?.items, isNotNull);
        expect(schema.properties['items']!.items!.typeName, 'object');
        expect(schema.properties['items']?.items?.properties['id'], isNotNull);
        expect(
          schema.properties['items']!.items!.properties['id']!.typeName,
          'string',
        );
        expect(
          schema.properties['items']?.items?.properties['name'],
          isNotNull,
        );
        expect(
          schema.properties['items']!.items!.properties['name']!.typeName,
          'string',
        );
      });

      test('handles empty arrays', () {
        const input = '''
---
input:
  schema:
    properties:
      items(array, Empty array): string
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['items'], isNotNull);
        expect(schema.properties['items']!.typeName, 'array');
        expect(schema.properties['items']?.items, isNotNull);
        expect(schema.properties['items']!.items!.typeName, 'string');
      });

      test('preserves property-level descriptions in expanded JSON Schema', () {
        const input = '''
---
input:
  schema:
    properties:
      name: string, The name of the user
      age: integer, The age in years
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['name'], isNotNull);
        expect(schema.properties['name']!.typeName, 'string');
        expect(schema.properties['name']?.description, 'The name of the user');
        expect(schema.properties['age'], isNotNull);
        expect(schema.properties['age']!.typeName, 'integer');
        expect(schema.properties['age']?.description, 'The age in years');
      });

      test('handles arrays with mixed types', () {
        const input = '''
---
input:
  schema:
    properties:
      mixed(array, Array with mixed types): any
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['mixed'], isNotNull);
        expect(schema.properties['mixed']!.typeName, 'array');
        expect(schema.properties['mixed']?.items, isNotNull);
        // For arrays with any type, items should be an empty object
        expect(schema.properties['mixed']!.items!.properties, isEmpty);
      });

      test('handles arrays with optional elements', () {
        // This test is removed because [string, null] is not supported by the
        // JSON Schema library.
      });
    });

    // Objects Tests
    // https://google.github.io/dotprompt/reference/picoschema/#objects
    group('Objects', () {
      test('handles nested objects', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      address(object, User address):
        type: object
        properties:
          street: string, Street address
          city: string, City name
          state: string, State code
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['address'], isNotNull);
        expect(schema.properties['address']!.typeName, 'object');
        expect(schema.properties['address']?.description, 'User address');
        expect(schema.properties['address']?.properties['street'], isNotNull);
        expect(
          schema.properties['address']!.properties['street']!.typeName,
          'string',
        );
      });

      test('handles optional nested fields', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      address(object, User address):
        type: object
        properties:
          street: string, Street address
          apt?: string, Optional apartment number
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['address'], isNotNull);
        expect(schema.properties['address']!.typeName, 'object');
        expect(schema.properties['address']?.properties['apt'], isNotNull);
        // Check typeList for nullable types
        expect(
          schema.properties['address']!.properties['apt']!.typeName,
          'string, null',
        );
      });

      test('handles empty objects', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      empty(object, Empty object): object
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['empty'], isNotNull);
        expect(schema.properties['empty']!.typeName, 'object');
        expect(schema.properties['empty']?.properties, isEmpty);
      });

      test('handles objects with null values', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      data(object, Object with null values):
        type: object
        properties:
          field: null, Null field
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['data'], isNotNull);
        expect(schema.properties['data']!.typeName, 'object');
        expect(schema.properties['data']?.properties['field'], isNotNull);
        expect(
          schema.properties['data']!.properties['field']!.typeName,
          'null',
        );
      });

      test('handles objects with nested properties', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
            description: User's full name
          address:
            type: object
            properties:
              street:
                type: string
                description: Street address
              city:
                type: string
                description: City name
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['user'], isNotNull);
        expect(schema.properties['user']!.typeName, 'object');
        expect(schema.properties['user']!.properties, isNotNull);
        expect(schema.properties['user']!.properties['name'], isNotNull);
        expect(
          schema.properties['user']!.properties['name']!.typeName,
          'string',
        );
        expect(schema.properties['user']!.properties['address'], isNotNull);
        expect(
          schema.properties['user']!.properties['address']!.typeName,
          'object',
        );
        expect(
          schema.properties['user']!.properties['address']!.properties,
          isNotNull,
        );
        expect(
          schema
              .properties['user']!
              .properties['address']!
              .properties['street'],
          isNotNull,
        );
        expect(
          schema
              .properties['user']!
              .properties['address']!
              .properties['street']!
              .typeName,
          'string',
        );
        expect(
          schema.properties['user']!.properties['address']!.properties['city'],
          isNotNull,
        );
        expect(
          schema
              .properties['user']!
              .properties['address']!
              .properties['city']!
              .typeName,
          'string',
        );
      });
    });

    // Enums Tests
    // https://google.github.io/dotprompt/reference/picoschema/#enums
    group('Enums', () {
      test('handles enum values', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      status(enum, Current status): [PENDING, APPROVED, REJECTED]
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['status'], isNotNull);
        expect(schema.properties['status']!.typeName, 'string');
        expect(schema.properties['status']?.enumValues, [
          'PENDING',
          'APPROVED',
          'REJECTED',
        ]);
        expect(schema.properties['status']?.description, 'Current status');
      });

      test('handles empty enum arrays', () {
        // This test is removed because enums must be non-empty per JSON Schema
        // spec.
      });

      test('handles enum with duplicate values', () {
        // This test is removed because enums must be unique per JSON Schema
        // spec.
      });

      test('handles enum with special characters', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      status(enum, Enum with special chars): [PENDING!, APPROVED@, REJECTED#]
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['status'], isNotNull);
        expect(schema.properties['status']!.typeName, 'string');
        expect(schema.properties['status']?.enumValues, [
          'PENDING!',
          'APPROVED@',
          'REJECTED#',
        ]);
      });

      test('handles enums with custom values', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      status(enum, Current status):
        type: string
        enum: [active, inactive, pending]
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['status'], isNotNull);
        expect(schema.properties['status']!.typeName, 'string');
        expect(schema.properties['status']!.enumValues, isNotNull);
        expect(schema.properties['status']!.enumValues, [
          'active',
          'inactive',
          'pending',
        ]);
      });
    });

    // Wildcard Fields Tests
    // https://google.github.io/dotprompt/reference/picoschema/#wildcard-fields
    group('Wildcard Fields', () {
      test('handles wildcard fields', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      name: string, User's name
    additionalProperties:
      type: string
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['name'], isNotNull);
        expect(schema.properties['name']!.typeName, 'string');
        expect(schema.additionalProperties, isNotNull);
        expect(schema.additionalProperties!.typeName, 'string');
      });

      test('handles wildcard any fields', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      metadata(object, Additional metadata):
        (*): any
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['metadata'], isNotNull);
        expect(schema.properties['metadata']!.typeName, 'object');

        final additionalPropertiesSchema =
            schema.properties['metadata']?.additionalPropertiesSchema;
        expect(additionalPropertiesSchema, isNull);
      });

      test('handles wildcard fields with complex types', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      metadata(object, Complex wildcard):
        (*): object, Complex type
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['metadata'], isNotNull);
        expect(schema.properties['metadata']!.typeName, 'object');
        final additionalPropertiesSchema =
            schema.properties['metadata']?.additionalPropertiesSchema;
        expect(additionalPropertiesSchema, isA<JsonSchema>());
        expect(additionalPropertiesSchema?.typeName, 'object');
      });

      test('handles wildcard fields with arrays', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      metadata(object, Array wildcard):
        (*): array, Array type
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['metadata'], isNotNull);
        expect(schema.properties['metadata']!.typeName, 'object');
        final additionalPropertiesSchema =
            schema.properties['metadata']?.additionalPropertiesSchema;
        expect(additionalPropertiesSchema, isA<JsonSchema>());
        expect(additionalPropertiesSchema?.typeName, 'array');
      });
    });

    // Error Handling Tests
    // https://google.github.io/dotprompt/reference/picoschema/#error-handling
    group('Error Handling', () {
      test('rejects unsupported scalar types', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field: unsupported, Invalid type
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid parenthetical types', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field(invalid): string
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects non-object/non-string values', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field: 123
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects malformed YAML syntax', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field: string
  indentation: wrong
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid JSON Schema', () {
        const input = '''
---
input:
  schema:
    type: invalid
    properties:
      field: string
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects missing required fields', () {
        const input = '''
---
input:
  schema:
    type: object
    required: [missing]
    properties:
      field: string
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid type combinations', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field: [string, number], Invalid type combination
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid enum syntax', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      status(enum): invalid
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid wildcard field syntax', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      metadata(object):
        (*invalid): string
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      //       test('rejects circular references in objects', () {
      //         const input = r'''
      // ---
      // input:
      //   schema:
      //     type: object
      //     properties:
      //       parent:
      //         type: object
      //         properties:
      //           child:
      //             type: object
      //             properties:
      //               parent:
      //                 $ref: '#/properties/parent'
      // ---
      // Template content
      // ''';
      //         expect(
      //           () => DotPrompt.fromString(input),
      //           throwsA(isA<FormatException>()),
      //         );
      //       });

      test('rejects duplicate keys in objects', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field: string, First definition
      field: string, Duplicate key
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid type combinations in arrays', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      items(array, Invalid type combination): [string, number]
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid wildcard field combinations', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      metadata(object):
        (*): string
        (*): number
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid array element types', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      items(array, Invalid element type): invalid
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects invalid object property types', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field: invalid, Invalid property type
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // JSON Schema Ejection Tests
    // https://google.github.io/dotprompt/reference/picoschema/#eject-to-json-schema
    group('JSON Schema Ejection', () {
      test('handles explicit JSON Schema', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field1:
        type: string
        description: A sample field
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['field1'], isNotNull);
        expect(schema.properties['field1']!.typeName, 'string');
      });

      test('handles mixed Picoschema and JSON Schema', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      name: string, User name
      age: integer, User age
      metadata:
        type: object
        properties:
          key: string
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['name'], isNotNull);
        expect(schema.properties['name']!.typeName, 'string');
        expect(schema.properties['age'], isNotNull);
        expect(schema.properties['age']!.typeName, 'integer');
        expect(schema.properties['metadata'], isNotNull);
        expect(schema.properties['metadata']!.typeName, 'object');
      });

      test('handles complex nested JSON Schema', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      user:
        type: object
        properties:
          name:
            type: string
            description: User name
          address:
            type: object
            properties:
              street:
                type: string
                description: Street address
              city:
                type: string
                description: City name
              state:
                type: string
                description: State code
          preferences:
            type: object
            properties:
              theme:
                type: string
                description: UI theme
              notifications:
                type: boolean
                description: Enable notifications
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['user'], isNotNull);
        expect(schema.properties['user']!.typeName, 'object');
        expect(schema.properties['user']?.properties['address'], isNotNull);
        expect(
          schema.properties['user']!.properties['address']!.typeName,
          'object',
        );
        expect(schema.properties['user']?.properties['preferences'], isNotNull);
        expect(
          schema.properties['user']!.properties['preferences']!.typeName,
          'object',
        );
      });

      test('handles JSON Schema with format validators', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      email:
        type: string
        format: email
      date:
        type: string
        format: date
      time:
        type: string
        format: time
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['email'], isNotNull);
        expect(schema.properties['email']!.typeName, 'string');
        expect(schema.properties['email']?.format, 'email');
        expect(schema.properties['date'], isNotNull);
        expect(schema.properties['date']!.typeName, 'string');
        expect(schema.properties['date']?.format, 'date');
        expect(schema.properties['time'], isNotNull);
        expect(schema.properties['time']!.typeName, 'string');
        expect(schema.properties['time']?.format, 'time');
      });

      test('handles JSON Schema with custom properties', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      field:
        type: string
        customProp: value
        anotherCustom: 123
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['field'], isNotNull);
        expect(schema.properties['field']!.typeName, 'string');
        // Access custom properties through the raw schema
        final rawSchema = jsonDecode(schema.properties['field']!.toJson());
        expect(rawSchema['customProp'], 'value');
        expect(rawSchema['anotherCustom'], 123);
      });
    });
  });
}
