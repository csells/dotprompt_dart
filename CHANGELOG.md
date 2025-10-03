## 0.4.0

- Thanks to gspencergoog for [a
  PR](https://github.com/csells/dotprompt_dart/pull/2) that introduces support
  for Mustache partials in .prompt files, allowing for reusable template
  snippets.

## 0.3.0

- Enabled web and wasm compatibility
- Breaking Change: replaced DotPrompt.file(filename) with
  DotPrompt.stream(bytes, name: filename). This allows for web compatibility w/o
  reduced functionality. Here's how to migrate your code:

```dart
  // old code
  const filename = 'example/prompts/greet.prompt';
  final prompt = await DotPrompt.file(filename));

  // new code
  const filename = 'example/prompts/greet.prompt';
  final prompt = await DotPrompt.stream(File(filename).openRead(), name: filename);
```

## 0.2.0

- integration with [dartantic_ai](https://pub.dev/packages/dartantic_ai)
- `DotPrompt` constructor name changes
- `DotPrompt.render` argument changes

## 0.1.0

- Initial version.
