// ignore_for_file: avoid_dynamic_calls, avoid_print

import 'package:dotprompt/dot_prompt.dart';
import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';

import 'test_utility.dart';

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
    type: object
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
    type: object
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
    type: object
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
    type: object
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
    type: object
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
    type: object
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
    });

    // Optional Fields Tests
    // https://google.github.io/dotprompt/reference/picoschema/#optional-fields
    group('Optional Fields', () {
      test('handles optional fields', () {
        const input = '''
---
input:
  schema:
    type: object
    required: [name]
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
        expect(schema.requiredProperties, ['name']);
        expect(schema.properties['subtitle'], isNotNull);
        expect(schema.properties['subtitle']!.typeName, 'string, null');
      });

      test('optional fields are nullable', () {
        const input = '''
---
input:
  schema:
    type: object
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
    });

    // Arrays Tests
    // https://google.github.io/dotprompt/reference/picoschema/#arrays
    group('Arrays', () {
      test('handles string array', () {
        const input = '''
---
input:
  schema:
    type: object
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
    type: object
    properties:
      items(array, List of items):
        type: object
        properties:
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
    });

    // Wildcard Fields Tests
    // https://google.github.io/dotprompt/reference/picoschema/#wildcard-fields
    group('Wildcard Fields', () {
      test('handles wildcard string fields', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      metadata(object, Additional metadata):
        (*): string
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        final schema = prompt.frontMatter.input.schema;
        // Debug output before assertions
        print('Expanded schema: \\${schema?.toJson()}');
        print(
          'metadata property schema: \\${schema?.properties['metadata']?.toJson()}',
        );
        expect(schema, isNotNull);
        expect(schema!.typeName, 'object');
        expect(schema.properties['metadata'], isNotNull);
        expect(schema.properties['metadata']!.typeName, 'object');

        final additionalPropertiesSchema =
            schema.properties['metadata']?.additionalPropertiesSchema;
        expect(additionalPropertiesSchema, isA<JsonSchema>());
        expect(additionalPropertiesSchema?.typeName, 'string');
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
    });
  });
}
