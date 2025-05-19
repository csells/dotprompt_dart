// ignore_for_file: avoid_print

import 'package:dotprompt_dart/dotprompt_dart.dart';

void main() async {
  final prompt = await DotPrompt.file('example/prompts/greet.prompt');
  final front = prompt.frontMatter; // the model info, settings, etc.
  final result = prompt.render({'name': 'Chris'});

  print('\n# Front Matter');
  print(front);

  print('\n# Result');
  print(result);
}
