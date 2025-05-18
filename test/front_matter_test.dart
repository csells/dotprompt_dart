import 'package:dotprompt/dot_prompt.dart';
import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';

import 'test_utility.dart';

bool isSchemaEmpty(JsonSchema? schema) {
  if (schema == null) return true;
  if (schema.type == null && (schema.properties.isEmpty)) return true;
  return false;
}

void main() {
  group('Frontmatter', () {
    // Basic Structure Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#structure
    group('Structure', () {
      test('handles empty frontmatter', () {
        const input = '''
---
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.name, isNull);
        expect(prompt.frontMatter.model, isNull);
        expect(prompt.template, equals('Template content'));
      });

      test('handles missing frontmatter', () {
        const input = 'Template content';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.name, isNull);
        expect(prompt.frontMatter.model, isNull);
        expect(prompt.template, equals('Template content'));
      });

      test('handles special characters in values', () {
        const input = '''
---
name: test
myext.multiline: |
  Line 1
  Line 2
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.name, 'test');
        // ignore: avoid_dynamic_calls
        expect(prompt.frontMatter.ext['myext']['multiline'], 'Line 1\nLine 2');
      });

      test('handles malformed YAML gracefully', () {
        const input = '''
---
name: testPrompt
model: googleai/gemini-1.5-flash
  indentation: wrong
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // Standard Fields Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#available-fields
    group('Standard Fields', () {
      test('handles name field', () {
        const input = '''
---
name: testPrompt
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.name, 'testPrompt');
      });

      test('handles model field', () {
        const input = '''
---
model: gemini-2.0-pro
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.model, 'gemini-2.0-pro');
      });

      test('handles tools array correctly', () {
        const input = '''
---
tools:
  - timeOfDay
  - weather
  - calendar
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(
          prompt.frontMatter.tools,
          equals(['timeOfDay', 'weather', 'calendar']),
        );
      });

      test('handles config fields correctly', () {
        const input = '''
---
config:
  version: gemini-1.5-flash-latest
  temperature: 0.7
  topK: 20
  topP: 0.8
  stopSequences:
    - STOPSTOPSTOP
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(
          prompt.frontMatter.config['version'],
          equals('gemini-1.5-flash-latest'),
        );
        expect(prompt.frontMatter.config['temperature'], equals(0.7));
        expect(prompt.frontMatter.config['topK'], equals(20));
        expect(prompt.frontMatter.config['topP'], equals(0.8));
        expect(
          prompt.frontMatter.config['stopSequences'],
          equals(['STOPSTOPSTOP']),
        );
      });
    });

    // Input/Output Schema Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#input
    // https://google.github.io/dotprompt/reference/frontmatter/#output
    group('Input/Output Schema', () {
      test('handles input schema correctly', () {
        const input = '''
---
input:
  schema:
    type: object
    properties:
      name:
        type: string
    required: [name]
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.input.schema, isNotNull);
        expect(prompt.frontMatter.input.schema!.typeName, 'object');
        expect(prompt.frontMatter.input.schema?.properties['name'], isNotNull);
        expect(
          prompt.frontMatter.input.schema!.properties['name']!.typeName,
          'string',
        );
      });

      test('handles output schema correctly', () {
        const input = '''
---
output:
  schema:
    type: object
    properties:
      greeting:
        type: string
    required: [greeting]
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.output.schema, isNotNull);
        expect(prompt.frontMatter.output.schema!.typeName, 'object');
        expect(
          prompt.frontMatter.output.schema!.properties['greeting'],
          isNotNull,
        );
        expect(
          prompt.frontMatter.output.schema!.properties['greeting']!.typeName,
          'string',
        );
      });

      test('handles empty collections', () {
        const input = '''
---
input:
  default: {}
  schema: {}
output:
  schema: {}
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.input.defaultValues, isEmpty);
        expect(isSchemaEmpty(prompt.frontMatter.input.schema), isTrue);
        expect(isSchemaEmpty(prompt.frontMatter.output.schema), isTrue);
      });
    });

    // Namespaced Fields Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#frontmatter-extensions
    group('Namespaced Fields', () {
      test('handles namespaced fields correctly', () {
        const input = '''
---
name: test
myext.level: 1
myext.nested.field: value
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.name, 'test');
        // ignore: avoid_dynamic_calls
        expect(prompt.frontMatter.ext['myext']['level'], 1);
        // ignore: avoid_dynamic_calls
        expect(prompt.frontMatter.ext['myext']['nested']['field'], 'value');
      });

      test('rejects non-namespaced custom fields', () {
        const input = '''
---
name: test
customField: value
---
Template content
''';
        expect(
          () => DotPrompt.fromString(input),
          throwsA(isA<FormatException>()),
        );
      });
    });

    // Variant Field Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#variant
    group('Variant Field', () {
      test('handles variant field correctly', () {
        const input = '''
---
name: testPrompt
variant: formal
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.variant, 'formal');
      });
    });

    // Input Defaults Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#input
    group('Input Defaults', () {
      test('handles input defaults correctly', () {
        const input = '''
---
input:
  default:
    name: Guest
    language: en
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.input.defaultValues['name'], 'Guest');
        expect(prompt.frontMatter.input.defaultValues['language'], 'en');
      });
    });

    // Output Format Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#output
    group('Output Format', () {
      test('handles output format correctly', () {
        const input = '''
---
output:
  format: json
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.output.format, 'json');
      });

      test('defaults to text format when not specified', () {
        const input = '''
---
output: {}
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.output.format, 'text');
      });
    });

    // Metadata Field Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#metadata
    group('Metadata Field', () {
      test('handles metadata field correctly', () {
        const input = '''
---
metadata:
  customKey:
    customValue: 123
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        // ignore: avoid_dynamic_calls
        expect(prompt.frontMatter.metadata['customKey']['customValue'], 123);
      });
    });

    // Namespaced Fields Edge Cases
    // https://google.github.io/dotprompt/reference/frontmatter/#frontmatter-extensions
    group('Namespaced Fields Edge Cases', () {
      test('handles deeply nested namespaced fields', () {
        const input = '''
---
name: test
myext.level1.level2.level3.field: value
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        // ignore: avoid_dynamic_calls
        expect(
          // ignore: avoid_dynamic_calls
          prompt
              .frontMatter
              .ext['myext']['level1']['level2']['level3']['field'],
          'value',
        );
      });

      test('handles namespaced fields with array values', () {
        const input = '''
---
name: test
myext.array: [1, 2, 3]
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        // ignore: avoid_dynamic_calls
        expect(prompt.frontMatter.ext['myext']['array'], [1, 2, 3]);
      });
    });

    // Model Field Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#model
    group('Model Field', () {
      test('handles model field with version', () {
        const input = '''
---
model: googleai/gemini-1.5-flash
config:
  version: gemini-1.5-flash-latest
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.frontMatter.model, 'googleai/gemini-1.5-flash');
        expect(prompt.frontMatter.config['version'], 'gemini-1.5-flash-latest');
      });
    });

    // Default Values Tests
    // https://google.github.io/dotprompt/reference/frontmatter/#structure
    group('Default Values', () {
      test('applies defaults for missing properties', () {
        const input = '''
---
model: gemini-2.0-pro
---
Template content
''';
        final defaults = {
          'name': 'defaultPrompt',
          'variant': 'default',
          'config': {'temperature': 0.5, 'topK': 40},
        };
        final prompt = DotPrompt.fromString(input, defaults: defaults);
        expect(prompt.frontMatter.name, 'defaultPrompt');
        expect(prompt.frontMatter.variant, 'default');
        expect(
          prompt.frontMatter.model,
          'gemini-2.0-pro',
        ); // Should not be overridden
        expect(prompt.frontMatter.config['temperature'], 0.5);
        expect(prompt.frontMatter.config['topK'], 40);
      });

      test('rejects non-standard properties in defaults', () {
        const input = '''
---
model: gemini-2.0-pro
---
Template content
''';
        final defaults = {
          'name': 'defaultPrompt',
          'customField': 'value', // Non-standard field
        };
        expect(
          () => DotPrompt.fromString(input, defaults: defaults),
          throwsA(isA<FormatException>()),
        );
      });

      test('does not override existing front matter values with defaults', () {
        const input = '''
---
name: explicitName
variant: explicitVariant
model: gemini-2.0-pro
config:
  temperature: 0.8
  topK: 20
---
Template content
''';
        final defaults = {
          'name': 'defaultName',
          'variant': 'defaultVariant',
          'config': {'temperature': 0.5, 'topK': 40},
        };
        final prompt = DotPrompt.fromString(input, defaults: defaults);
        expect(prompt.frontMatter.name, 'explicitName');
        expect(prompt.frontMatter.variant, 'explicitVariant');
        expect(prompt.frontMatter.model, 'gemini-2.0-pro');
        expect(prompt.frontMatter.config['temperature'], 0.8);
        expect(prompt.frontMatter.config['topK'], 20);
      });
    });
  });
}
