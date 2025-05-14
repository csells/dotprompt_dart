import 'dart:io';

import 'package:dotprompt/dot_prompt.dart';
import 'package:test/test.dart';

void main() {
  group('DotPrompt', () {
    const promptPath = 'example/prompts/greet.prompt';
    late DotPrompt dotPrompt;

    setUpAll(() async {
      dotPrompt = await DotPrompt.fromFile(promptPath);
    });

    // Tests basic frontmatter fields from spec: name, model, temperature
    // https://google.github.io/dotprompt/reference/frontmatter/#available-fields
    test('loads prompt metadata and template', () {
      expect(dotPrompt.metadata.name, 'greet');
      expect(
        dotPrompt.metadata.ext['myext']['description'],
        'A simple greeting prompt',
      );
      expect(dotPrompt.metadata.model, 'gemini-2.0-pro');
      expect(dotPrompt.metadata.ext['myext']['temperature'], 0.7);
      expect(dotPrompt.metadata.inputSchema, isNotNull);
      expect(dotPrompt.metadata.outputSchema, isNotNull);
      expect(dotPrompt.template, contains('Hello {{name}}!'));
    });

    // Tests template rendering functionality
    // https://google.github.io/dotprompt/reference/template/
    test('renders template with input', () {
      final output = dotPrompt.render({'name': 'Chris'});
      expect(output, contains('Hello Chris!'));
    });

    // Tests full frontmatter parsing including all required fields
    // https://google.github.io/dotprompt/reference/frontmatter/#structure
    test('fromString parses prompt correctly', () async {
      final promptString =
          await File('example/prompts/greet.prompt').readAsString();
      final dotPrompt = DotPrompt.fromString(promptString);
      final output = dotPrompt.render({'name': 'Chris'});
      expect(output, contains('Hello Chris!'));

      expect(dotPrompt.metadata.name, 'greet');
      expect(
        dotPrompt.metadata.ext['myext']['description'],
        'A simple greeting prompt',
      );
      expect(dotPrompt.metadata.model, 'gemini-2.0-pro');
      expect(dotPrompt.metadata.ext['myext']['temperature'], 0.7);
      expect(dotPrompt.metadata.inputSchema, isNotNull);
      expect(dotPrompt.metadata.outputSchema, isNotNull);
      expect(dotPrompt.template, contains('Hello {{name}}!'));
    });

    group('Frontmatter handling', () {
      // Tests empty frontmatter case
      // https://google.github.io/dotprompt/reference/frontmatter/#structure
      test('handles empty frontmatter', () {
        const input = '''
---
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.metadata.name, isNull);
        expect(prompt.metadata.model, isNull);
        expect(prompt.template, equals('Template content'));
      });

      // Tests missing frontmatter case
      // https://google.github.io/dotprompt/reference/frontmatter/#structure
      test('handles missing frontmatter', () {
        const input = 'Template content';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.metadata.name, isNull);
        expect(prompt.metadata.model, isNull);
        expect(prompt.template, equals('Template content'));
      });

      // Tests namespaced fields handling
      // https://google.github.io/dotprompt/reference/frontmatter/#frontmatter-extensions
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
        expect(prompt.metadata.name, 'test');
        expect(prompt.metadata.ext['myext']['level'], 1);
        expect(prompt.metadata.ext['myext']['nested']['field'], 'value');
      });

      // Tests special character handling in values
      // https://google.github.io/dotprompt/reference/frontmatter/#structure
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
        expect(prompt.metadata.name, 'test');
        expect(prompt.metadata.ext['myext']['multiline'], 'Line 1\nLine 2');
      });

      // Tests config field handling
      // https://google.github.io/dotprompt/reference/frontmatter/#config
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
          prompt.metadata.config['version'],
          equals('gemini-1.5-flash-latest'),
        );
        expect(prompt.metadata.config['temperature'], equals(0.7));
        expect(prompt.metadata.config['topK'], equals(20));
        expect(prompt.metadata.config['topP'], equals(0.8));
        expect(
          prompt.metadata.config['stopSequences'],
          equals(['STOPSTOPSTOP']),
        );
      });

      // Tests tools array handling
      // https://google.github.io/dotprompt/reference/frontmatter/#tools
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
          prompt.metadata.tools,
          equals(['timeOfDay', 'weather', 'calendar']),
        );
      });

      // Tests empty collections handling
      // https://google.github.io/dotprompt/reference/frontmatter/#structure
      test('handles empty arrays and maps', () {
        const input = '''
---
tools: []
config: {}
input:
  default: {}
  schema: {}
output:
  schema: {}
---
Template content
''';
        final prompt = DotPrompt.fromString(input);
        expect(prompt.metadata.tools, isEmpty);
        expect(prompt.metadata.config, isEmpty);
        expect(prompt.metadata.inputDefaults, isEmpty);
        expect(prompt.metadata.inputSchema, isEmpty);
        expect(prompt.metadata.outputSchema, isEmpty);
      });

      // Tests YAML parsing error handling
      // https://google.github.io/dotprompt/reference/frontmatter/#structure
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
  });
}
