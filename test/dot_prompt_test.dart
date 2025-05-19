import 'dart:io';

import 'package:dotprompt_dart/dotprompt_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DotPrompt', () {
    const promptPath = 'example/prompts/greet.prompt';
    late DotPrompt dotPrompt;

    setUpAll(() async {
      dotPrompt = await DotPrompt.file(promptPath);
    });

    test('loads prompt front matter and template', () {
      expect(dotPrompt.frontMatter.name, 'greet');
      expect(
        // ignore: avoid_dynamic_calls
        dotPrompt.frontMatter.ext['myext']['description'],
        'A simple greeting prompt',
      );
      expect(dotPrompt.frontMatter.model, 'gemini-2.0-pro');
      // ignore: avoid_dynamic_calls
      expect(dotPrompt.frontMatter.ext['myext']['temperature'], 0.7);
      expect(dotPrompt.frontMatter.input.schema, isNotNull);
      expect(dotPrompt.frontMatter.output.schema, isNotNull);
      expect(dotPrompt.template, contains('Hello {{name}}!'));
    });

    test('renders template with input', () {
      final output = dotPrompt.render({'name': 'Chris'});
      expect(output, contains('Hello Chris!'));
    });

    test('fromString parses prompt correctly', () async {
      final promptString =
          await File('example/prompts/greet.prompt').readAsString();
      final dotPrompt = DotPrompt(promptString);
      final output = dotPrompt.render({'name': 'Chris'});
      expect(output, contains('Hello Chris!'));

      expect(dotPrompt.frontMatter.name, 'greet');
      expect(
        // ignore: avoid_dynamic_calls
        dotPrompt.frontMatter.ext['myext']['description'],
        'A simple greeting prompt',
      );
      expect(dotPrompt.frontMatter.model, 'gemini-2.0-pro');
      // ignore: avoid_dynamic_calls
      expect(dotPrompt.frontMatter.ext['myext']['temperature'], 0.7);
      expect(dotPrompt.frontMatter.input.schema, isNotNull);
      expect(dotPrompt.frontMatter.output.schema, isNotNull);
      expect(dotPrompt.template, contains('Hello {{name}}!'));
    });
  });
}
