// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dotprompt_dart/dotprompt_dart.dart';

void main() async {
  const filename = 'example/prompts/greet.prompt';
  final prompt = await DotPrompt.stream(
    File(filename).openRead(),
    name: filename,
  );
  final front = prompt.frontMatter; // the model info, settings, etc.
  final result = prompt.render({'name': 'Chris'});

  print('\n# Front Matter');
  print(front);

  print('\n# Result');
  print(result);
}
