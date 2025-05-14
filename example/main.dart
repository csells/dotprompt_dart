// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:dotprompt/dot_prompt.dart';

void main() async {
  final prompt = await DotPrompt.fromFile('example/prompts/greet.prompt');
  final meta = prompt.metadata; // the model info, settings, etc.
  final result = prompt.render({'name': 'Chris'});

  print('# Metadata');
  print(const JsonEncoder.withIndent('  ').convert(meta));

  print('# Result');
  print(result);
}
