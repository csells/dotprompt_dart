import 'package:dotprompt/dot_prompt.dart';
import 'package:test/test.dart';

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
        expect(prompt.frontMatter.inputSchema, isNotNull);
        expect(prompt.frontMatter.inputSchema!['type'], 'object');
        expect(
          // ignore: avoid_dynamic_calls
          prompt.frontMatter.inputSchema!['properties']['name']['type'],
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
        expect(prompt.frontMatter.outputSchema, isNotNull);
        expect(prompt.frontMatter.outputSchema!['type'], 'object');
        expect(
          // ignore: avoid_dynamic_calls
          prompt.frontMatter.outputSchema!['properties']['greeting']['type'],
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
        expect(prompt.frontMatter.inputDefaults, isEmpty);
        expect(prompt.frontMatter.inputSchema, isEmpty);
        expect(prompt.frontMatter.outputSchema, isEmpty);
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
  });
}
