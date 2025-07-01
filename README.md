# dotprompt_dart

A Dart package that treats `.prompt` files as executable units for LLM
interactions, providing schema validation, template rendering, and model
configuration management. This package does not execute a `.prompt` file by
itself, but support for .prompt files is available in
[dartantic_ai](https://pub.dev/packages/dartantic_ai) as of v0.3.0.

The [dotprompt_dart](https://pub.dev/packages/dotprompt_dart) package is modeled
after [Google's dotprompt library](https://github.com/google/dotprompt).
Google's implementation supports Go, Java, Javascript and Python, whereas this
implementation supports Dart. Also, Google's implementation is used as part of
the implementation for GenKit, which also supports those other languages, but
not Dart. 

Unlike Google's implementation, this implementation doesn't do the execution of
model prompts; instead, it uses dartantic_ai for the execution. You can
absolutely use dotprompt_dart without dartantic_ai by simply using the schemas,
model parameters, template expansion features, etc. and then feed all of that
data into the model of your choice. That's what dartantic_ai uses it for.

Both Google's implementation and mine are based on [the dotprompt
specification](https://google.github.io/dotprompt/getting-started/). There are
100+ tests currently attempting to be faithful to that specification, most of
them dedicated to the successful conversion of the Pico Schema to a JSON Schema
object. Pico Schema is a handy shorthand syntax when compared against the JSON
Schema spec, but for use in Dart code, a `JsonSchema` object is much more useful
and the one from the [json_schema](https://pub.dev/packages/json_schema) package
particularly so. No matter which you use -- Pico Schema or JSON Schema -- you're
going to get out a `JsonSchema` object for your use.

## Features

- Prompt File Support: Parse and execute `.prompt` files with YAML front-matter
  and Handlebars templates
- Schema Validation: Built-in support for [Pico
  Schema](https://google.github.io/dotprompt/reference/picoschema/) and JSON
  Schema for input/output validation
- Model Configuration: Manage model settings through front-matter configuration
- Type-Safe: The generated JSON Schema can be used to validate input to the
  template rendering as well as to provide type info for model output
- Extension Support: Custom configuration through namespaced keys (e.g.,
  `myext.temperature`)


## Migrating from 0.2.0 to 0.3.0

Version 0.3.0 introduces web and wasm compatibility by replacing the
`DotPrompt.file(filename)` constructor with `DotPrompt.stream(bytes, name:
filename)`. This change allows you to load prompt files from any byte stream,
not just the file system, making it compatible with browsers and other
platforms.

**Migration Example:**

```dart
// Old code (0.2.0)
const filename = 'example/prompts/greet.prompt';
final prompt = await DotPrompt.file(filename);

// New code (0.3.0+)
const filename = 'example/prompts/greet.prompt';
final prompt = await DotPrompt.stream(File(filename).openRead(), name: filename);
```

- The new API works with any `Stream<List<int>>`, so you can load prompts from
  assets, network, or other sources.
- The `name` parameter is optional but recommended for metadata and default
  inference.
- This change is required for web/wasm compatibility.

## Getting Started

Add `dotprompt_dart` to your `pubspec.yaml`:

```yaml
dependencies:
  dotprompt_dart: ^VERSION
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
import 'dart:io';

void main() async {
  // Load from file (0.3.0+)
  final greet = await DotPrompt.stream(File('prompts/greet.prompt').openRead(), name: 'prompts/greet.prompt');
  
  // Or load from string
  final promptString = '...';
  final greetFromString = DotPrompt(promptString);
  
  // Render the template
  final output = greet.render({'name': 'Chris'});
  print(output); // Hello Chris! How are you today?
  
  // Access front-matter metadata
  print(greet.frontMatter.name); // greet
  print(greet.frontMatter.model); // gemini-2.0-pro

  // Use this info to feed your prompt execution library of choice
  ...
}
```

## Schema Support

The package provides flexible schema validation through two approaches:

### Pico Schema

Pico Schema is a simplified, YAML-friendly schema syntax that is automatically
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
by the presence of a top-level `type` field which short-circuits the Pico Schema
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

### Input Validation and Defaults

The package validates input data against the schema during template rendering.
You can also provide default values that are used when fields are not specified
in the input:

```yaml
input:
  schema:
    type: object
    properties:
      name:
        type: string
      greeting:
        type: ["string", "null"]  # Optional field that can be null
      age:
        type: integer
        minimum: 0
    required: [name]  # Only name is required
  default:
    greeting: "Hello"  # Used when greeting is not provided
```

When rendering a template:
1. Default values are merged with provided input (input values take precedence)
2. The combined input is validated against the schema
3. If validation fails, a `ValidationException` is thrown with detailed error
   messages
4. If validation passes, the template is rendered with the combined input

For example:

```dart
final prompt = DotPrompt(promptString);

// Uses default greeting "Hello"
prompt.render({'name': 'World'}); // => "Hello World!"

// Overrides default greeting
prompt.render({'name': 'World', 'greeting': 'Hi'}); // => "Hi World!"

// Throws ValidationException - missing required 'name'
prompt.render({'greeting': 'Hi'});
```

## Handlebar Implementation Shortcomings

The template expansion used in the current version of dotprompt_dart is based on
the [mustache_template](https://pub.dev/packages/mustache_template) package.
It's a very capable and full-featured template expansion library, but
unfortunately it is not
[spec](https://google.github.io/dotprompt/reference/template/)-compliant.

Here's a list of the current short-comings that I know about:

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
