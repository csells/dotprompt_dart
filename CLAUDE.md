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

**Custom Handlebars-compatible implementation** in [lib/src/template/](lib/src/template/):
- State machine-based parser ([template_machine.dart](lib/src/template/template_machine.dart))
- Complete implementation of Handlebars syntax (variables, helpers, blocks, partials)
- **Goal: 100% spec compliance** with [dotprompt template spec](https://google.github.io/dotprompt/reference/template/)
- Built-in helpers: `#if`, `#unless`, `#each`, `#with`
- Dotprompt helpers: `json`, `role`, `history`, `media`, `section`
- Custom helper registration with full context access via `registerHelper()`
- Context variables: `@root`, `@metadata`, `@index`, `@first`, `@last`, `@key`
- Partials support via `DotPromptPartialResolver` (see [path_partial_resolver.dart](lib/src/path_partial_resolver.dart))

**Known gaps for 100% compliance** (see [PRD.md](PRD.md) "Known Gaps" section):
- Comments `{{!-- --}}`
- Whitespace control `~`
- Inline partials, block parameters, subexpressions
- Parent context navigation `../`

**CRITICAL Testing Requirement**:
- **Every spec feature MUST have comprehensive test coverage**
- Tests MUST validate both success and error cases
- Tests MUST cover edge cases (empty arrays, null values, missing properties)
- Tests MUST validate error messages are helpful and accurate
- Template tests are in [test/template_content_test.dart](test/template_content_test.dart)

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
- `path`: ^1.8.0 - Path manipulation
- `collection`: ^1.19.1 - Collection utilities
- **NO external template library** - custom implementation in `lib/src/template/`

## Testing Philosophy

Tests are comprehensive with:
- 100+ tests for Pico Schema conversion ([test/pico_schema_test.dart](test/pico_schema_test.dart))
- Comprehensive template tests ([test/template_content_test.dart](test/template_content_test.dart))
- **MUST achieve 100% coverage of template spec features**

Tests should be:
- Silent on success, report failures via `expect()`
- No print statements except for diagnostics (which should be removed before commit)
- Cover both success and error cases
- Test edge cases thoroughly
- Validate error messages are helpful
