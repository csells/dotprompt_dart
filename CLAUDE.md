# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Dart package for parsing `.prompt` files for LLM interactions. Based on [Google's dotprompt specification](https://google.github.io/dotprompt/getting-started/), this implementation converts Pico Schema to JSON Schema, provides schema validation, template rendering with Handlebars/Mustache, and model configuration management.

This package does NOT execute prompts itself - it parses and prepares them for execution by other libraries like [dartantic_ai](https://pub.dev/packages/dartantic_ai).

## Common Commands

### Testing
```bash
# Run all tests
dart test

# Run a single test file
dart test test/pico_schema_test.dart

# Run tests with verbose output
dart test --reporter=expanded
```

### Development
```bash
# Run the example
dart run example/main.dart

# Analyze code
dart analyze

# Format code
dart format .
```

### Publishing
```bash
# Check package for publish readiness
dart pub publish --dry-run

# Publish to pub.dev
dart pub publish
```

## Architecture

### Core Components

1. **DotPrompt** ([lib/src/dot_prompt.dart](lib/src/dot_prompt.dart)) - Main entry point
   - Parses .prompt files with YAML front-matter and Handlebars templates
   - Factory constructor `DotPrompt(String)` for string content
   - Static method `DotPrompt.stream(Stream<List<int>>, {name, defaults})` for loading from streams (required for web/wasm compatibility)
   - `render(Map<String, dynamic>)` method validates input against schema and renders template
   - Merges default values with input before validation

2. **PicoSchema** ([lib/src/pico_schema.dart](lib/src/pico_schema.dart)) - Schema conversion engine
   - Detects schema type (JSON Schema vs Pico Schema) using `schemaType()`
   - Top-level `type` property triggers JSON Schema mode (short-circuits Pico Schema parsing)
   - Mixed schemas throw `FormatException`
   - Expands Pico Schema shorthand into valid JSON Schema
   - 100+ tests ensure spec compliance
   - Key features:
     - Optional fields: `name?: string`
     - Type annotations: `settings(object)`, `tags(array)`
     - Enums: `theme: [light, dark]` or `theme(enum): [light, dark]`
     - Wildcards: `(*): any` for additionalProperties
     - Inline descriptions: `name: string, The user's name`

3. **DotPromptFrontMatter** ([lib/src/dot_prompt_front_matter.dart](lib/src/dot_prompt_front_matter.dart))
   - Parses YAML front-matter between `---` delimiters
   - Includes model config, input/output schemas, and custom extensions
   - Supports namespaced keys (e.g., `myext.temperature`)

4. **InputOutputConfig** ([lib/src/input_output_config.dart](lib/src/input_output_config.dart))
   - Manages input/output schemas and defaults
   - Creates `JsonSchema` objects from Pico Schema or JSON Schema
   - Stores default values for input validation

### Template System

Uses [mustache_template](https://pub.dev/packages/mustache_template) package for template expansion. NOT fully spec-compliant with Google's Handlebars implementation - see README.md "Handlebar Implementation Shortcomings" section for known limitations.

### Web/WASM Compatibility

Version 0.3.0+ replaced `DotPrompt.file(filename)` with `DotPrompt.stream(bytes, name: filename)` for web/wasm compatibility. Use `File(filename).openRead()` to create the stream for file system sources.

## Project-Specific Rules

### PRD Reference
- Read [PRD.md](PRD.md) at the start of each session
- Reference PRD when implementing features
- Update PRD if implementation requires requirement changes
- Document changes to core functionality, API design, architecture, dependencies, or user stories

### Collaboration Boundaries
- Only implement what is explicitly requested
- Present ideas as suggestions ("I have an idea...") without implementing
- Ask for clarification if scope is unclear
- Wait for explicit approval before actions beyond immediate request

### Validation & Planning
- Verify understanding before implementation
- Validate against [official dotprompt docs](https://google.github.io/dotprompt/)
- Check library implementation details and best practices
- Ensure changes align with existing codebase patterns

## Key Dependencies

- `json_schema`: ^5.2.1 - JSON Schema validation
- `yaml`: ^3.1.2 - YAML front-matter parsing
- `mustache_template`: ^2.0.0 - Template expansion
- `path`: ^1.8.0 - Path manipulation
- `collection`: ^1.19.1 - Collection utilities

## Testing Philosophy

Tests are comprehensive with 100+ tests focused on Pico Schema conversion. Tests should be silent on success and report failures via `expect()`. No print statements except for diagnostics (which should be removed before commit).
