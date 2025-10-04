import 'dart:io';

import 'package:dotprompt_dart/dotprompt_dart.dart';
import 'package:dotprompt_dart/src/path_partial_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('PathPartialResolver', () {
    late Directory tempDir;
    late Directory partialsDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dotprompt_test_');
      partialsDir = Directory('${tempDir.path}/partials')..createSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('resolves .prompt partial', () {
      File('${partialsDir.path}/_my_partial.prompt').writeAsStringSync('''
---
name: my_partial
---
Hello from the prompt partial!
''');

      final resolver = PathPartialResolver([partialsDir]);
      final template = resolver.resolve('my_partial');

      expect(template, isNotNull);
      expect(template, equals('Hello from the prompt partial!'));
    });

    test('resolves .mustache partial', () {
      File(
        '${partialsDir.path}/_my_partial.mustache',
      ).writeAsStringSync('Hello from the mustache partial!');

      final resolver = PathPartialResolver([partialsDir]);
      final template = resolver.resolve('my_partial');

      expect(template, isNotNull);
      expect(template, equals('Hello from the mustache partial!'));
    });

    test('returns null for non-existent partial', () {
      final resolver = PathPartialResolver([partialsDir]);
      final template = resolver.resolve('non_existent');
      expect(template, isNull);
    });

    test('DotPrompt renders template with partial', () {
      const mainPromptContent = '''
---
name: main
---
Main content: {{> my_partial }}
''';
      File('${partialsDir.path}/_my_partial.prompt').writeAsStringSync('''
---
name: my_partial
---
Partial content.
''');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = DotPrompt(mainPromptContent, partialResolver: resolver);
      final output = prompt.render(input: {}).trim();

      expect(output, equals('Main content: Partial content.'));
    });

    test('DotPrompt.stream renders template with partial', () async {
      final mainPromptFile = File('${tempDir.path}/main.prompt')
        ..writeAsStringSync('''
---
name: main
---
Stream content: {{> my_partial }}
''');
      File('${partialsDir.path}/_my_partial.prompt').writeAsStringSync('''
---
name: my_partial
---
Stream partial.
''');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = await DotPrompt.stream(
        mainPromptFile.openRead(),
        name: mainPromptFile.path,
        partialResolver: resolver,
      );
      final output = prompt.render(input: {}).trim();

      expect(output, equals('Stream content: Stream partial.'));
    });

    test('handles nested partials', () {
      const mainPromptContent = 'Main: {{> partial1 }}';
      File(
        '${partialsDir.path}/_partial1.prompt',
      ).writeAsStringSync('P1: {{> partial2 }}');
      File('${partialsDir.path}/_partial2.prompt').writeAsStringSync('P2');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = DotPrompt(mainPromptContent, partialResolver: resolver);
      final output = prompt.render(input: {}).trim();

      expect(output, equals('Main: P1: P2'));
    });
    test('extracts only template content from partial', () {
      const mainPromptContent = 'Main: {{> partial_with_front_matter }}';
      File(
        '${partialsDir.path}/_partial_with_front_matter.prompt',
      ).writeAsStringSync('''
---
name: partial
---
This is the actual template content.
''');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = DotPrompt(mainPromptContent, partialResolver: resolver);
      final output = prompt.render(input: {}).trim();

      expect(output, equals('Main: This is the actual template content.'));
    });

    test('partial with context from parent', () {
      const mainPromptContent = '''
---
name: main
input:
  schema:
    type: object
    properties:
      name:
        type: string
---
{{> greeting }}
''';
      File('${partialsDir.path}/_greeting.prompt').writeAsStringSync('''
Hello, {{name}}!
''');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = DotPrompt(mainPromptContent, partialResolver: resolver);
      final output = prompt.render(input: {'name': 'Alice'}).trim();

      expect(output, equals('Hello, Alice!'));
    });

    test('partial with scoped context', () {
      const mainPromptContent = '''
---
name: main
input:
  schema:
    type: object
    properties:
      user:
        type: object
---
{{> user_details user }}
''';
      File('${partialsDir.path}/_user_details.prompt').writeAsStringSync('''
Name: {{name}}, Email: {{email}}
''');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = DotPrompt(mainPromptContent, partialResolver: resolver);
      final output =
          prompt
              .render(
                input: {
                  'user': {'name': 'Bob', 'email': 'bob@example.com'},
                },
              )
              .trim();

      expect(output, equals('Name: Bob, Email: bob@example.com'));
    });

    test('partial in iteration', () {
      const mainPromptContent = '''
---
name: main
input:
  schema:
    type: object
    properties:
      users:
        type: array
---
{{#each users}}{{> user_item }}{{/each}}
''';
      File('${partialsDir.path}/_user_item.prompt').writeAsStringSync('''
User: {{name}}
''');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = DotPrompt(mainPromptContent, partialResolver: resolver);
      final output =
          prompt
              .render(
                input: {
                  'users': [
                    {'name': 'Alice'},
                    {'name': 'Bob'},
                  ],
                },
              )
              .trim();

      expect(output, contains('User: Alice'));
      expect(output, contains('User: Bob'));
    });

    test('partial merges named arguments with base context', () {
      const mainPromptContent = '''
---
name: main
input:
  schema:
    type: object
    properties:
      user:
        type: object
---
{{> badge user style="primary"}}
''';
      File('${partialsDir.path}/_badge.prompt').writeAsStringSync('''
Badge: {{style}} {{name}}
''');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = DotPrompt(mainPromptContent, partialResolver: resolver);
      final output =
          prompt
              .render(
                input: {
                  'user': {'name': 'Alice'},
                },
              )
              .trim();

      expect(output, equals('Badge: primary Alice'));
    });

    test('partial accepts explicit this parameter', () {
      const mainPromptContent = '''
---
name: main
input:
  schema:
    type: object
    properties:
      tags:
        type: array
        items:
          type: string
---
{{#each tags}}- {{> tag_item this }}\n{{/each}}
''';
      File('${partialsDir.path}/_tag_item.prompt').writeAsStringSync('''
Tag: {{.}}
''');

      final resolver = PathPartialResolver([partialsDir]);
      final prompt = DotPrompt(mainPromptContent, partialResolver: resolver);
      final output = prompt.render(
        input: {
          'tags': ['important', 'urgent'],
        },
      );

      expect(output, contains('Tag: important'));
      expect(output, contains('Tag: urgent'));
    });
  });
}
