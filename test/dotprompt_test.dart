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

    test('renders template with input', () {
      final output = dotPrompt.render({'name': 'Chris'});
      expect(output, contains('Hello Chris!'));
    });

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
  });
}
