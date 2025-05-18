# dotprompt_dart

A Dart package that treats `.prompt` files as executable units for LLM
interactions, providing schema validation, template rendering, and model
configuration management. This package does not execute a `.prompt` file by
itself, but support for .prompt files is available in
[dartantic_ai](https://pub.dev/packages/dartantic_ai) as of v0.3.0.

## Features

- 📝 **Prompt File Support**: Parse and execute `.prompt` files with YAML
  front-matter and Handlebars templates
- ✅ **Schema Validation**: Built-in support for
  [Picoschema](https://google.github.io/dotprompt/reference/picoschema/) and
  JSON Schema for input/output validation
- 🔧 **Model Configuration**: Manage model settings through front-matter
  configuration
- 🎯 **Type-Safe**: Future support for code generation to provide strongly-typed
  Dart interfaces
- 🛠️ **CLI Tools**: Upcoming support for linting, testing, and generating
  prompts

## Schema Support

The package provides flexible schema validation through two approaches:

### PicoSchema

PicoSchema is a simplified, YAML-friendly schema syntax that is automatically
converted to JSON Schema. You can use it for more readable schema definitions:

```yaml
input:
  schema:
    properties:
      name: string, The name of the user
      age?: integer, The age in years  # Optional field with ?
      settings(object):  # Type annotation with ()
        theme: [light, dark], Theme preference  # Enum using []
        notifications: boolean
      tags(array): string, List of user tags  # Array type
      (*): any  # Wildcard for additional properties
```

### JSON Schema

You can also use standard JSON Schema syntax directly. The package detects this
by the presence of a top-level `type` field which short-circutes the Pico Schema
parsing to "eject" your schema as JSON Schema:

```yaml
input:
  schema:
    type: object
    properties:
      name:
        type: string
        description: The name of the user
      age:
        type: [integer, "null"]  # Optional field using union type
      settings:
        type: object
        properties:
          theme:
            type: string
            enum: [light, dark]
          notifications:
            type: boolean
      tags:
        type: array
        items:
          type: string
    additionalProperties: true  # Equivalent to (*): any
```

### Schema Detection and Conversion

Both Pico Schema and JSON Schema result in a valid `JsonSchema` object that can
be used for:
- Input validation before template rendering
- Output validation after LLM responses
- Type-safe code generation (upcoming feature)

## Planned Features

The following template features are planned for future releases:

### Built-in Handlebars Helpers
- `#if` conditional blocks
- `else` blocks
- `#unless` blocks
- `#each` iteration with `@index`, `@first`, `@last` support

### Dotprompt Helpers
- `json` helper for JSON serialization
- `role` helper for multi-message prompts
- `history` helper for conversation context
- `media` helper for image content
- `section` helper for content positioning

### Custom Helpers
- Basic helpers with positional args
- Named argument support
- Block helpers
- Context access
- Error handling

### Context Variables
- `@metadata` access to prompt configuration
- `@root` context reference
- Message history access via `@metadata.messages`

## Getting Started

Add `dotprompt_dart` to your `pubspec.yaml`:

```yaml
dependencies:
  dotprompt_dart: ^0.1.0
```

## Usage

1. Create a `.prompt` file with front-matter and template:

```yaml
---
name: greet
model: gemini-2.0-pro
input:
  schema:
    properties:
      name: string, The name of the person to greet
output:
  schema:
    type: object
    properties:
      greeting:
        type: string
        description: The generated greeting
    required: [greeting]
myext.description: A simple greeting prompt
myext.temperature: 0.7
---

Hello {{name}}! How are you today? 
```

2. Load and use the prompt in your Dart code:

```dart
import 'package:dotprompt_dart/dotprompt_dart.dart';

void main() async {
  // Load from file
  final greet = await DotPrompt.fromFile('prompts/greet.prompt');
  
  // Or load from string
  final promptString = '...';
  final greetFromString = DotPrompt.fromString(promptString);
  
  // Render the template
  final output = greet.render({'name': 'Chris'});
  print(output); // Hello Chris! How are you today?
  
  // Access front-matter metadata
  print(greet.frontMatter.name); // greet
  print(greet.frontMatter.model); // gemini-2.0-pro
}
```

## Additional Information

- [Dotprompt Documentation](https://google.github.io/dotprompt/)
- [Front Matter
  Specification](https://google.github.io/dotprompt/reference/frontmatter/)
- [Template
  Specification](https://google.github.io/dotprompt/reference/template/)
- [Model Specification](https://google.github.io/dotprompt/reference/model/)

## Contributing

Contributions are welcome! Submit your
[issues](https://github.com/csells/dotprompt_dart/issues) or your
[PRs](https://github.com/csells/dotprompt_dart/pulls) today!