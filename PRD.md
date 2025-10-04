# Product Requirements Document  
**Project:** dotprompt for Dart

## Problem & Goal  
[Dart](https://dart.dev/) developers can already call LLMs, but prompt logic,
model configuration, schema‑validated I/O, and tool use are scattered across
ad‑hoc code.  
We will ship a first‑class Dart package that treats a [`.prompt`
file](https://google.github.io/dotprompt/getting-started/#the-prompt-file) as an
*executable unit*—parsing the
[front‑matter](https://google.github.io/dotprompt/reference/frontmatter/),
rendering the [Handlebars‑style
template](https://google.github.io/dotprompt/reference/template/), validating
[Picoschema](https://google.github.io/dotprompt/reference/picoschema/) I/O, and
making the client able to execute the request through any supported model
backend defined by the [model
spec](https://google.github.io/dotprompt/reference/model/). The result is
reproducible, testable prompting that feels as natural in Dart as it does today
in TypeScript via the [reference
implementations](https://github.com/google/dotprompt).  

## Scope  
1. **Core library `dotprompt_dart`** – runtime parser, renderer, validator,
   executor.  
2. **CLI `dotprompt`** – lint, preview, test, and code‑gen helpers.  
3. **Code‑gen builder** – optional build_runner that produces strongly‑typed
   Dart functions from `.prompt` files.  
4. **Examples & Docs** – reference app showing multi‑turn chat with tool calls.  

*Non‑goals (v1):* LLM-specific execution adaptors. spec‑test harness, IDE
plug‑in, non‑Dart runtimes.

## Detailed Requirements  

### Prompt Parsing  
* Accept a file with optional YAML
  [front‑matter](https://google.github.io/dotprompt/reference/frontmatter/)
  delimited by `---`. All fields are optional; defaults are inferred from
  filename and library settings. The front matter can be separated from the
  template content using the
  [fbh_front_matter](https://pub.dev/packages/fbh_front_matter) package.
* Preserve extensible dotted‑key namespaces under an `ext` map exactly as
  described in the spec.  
* Compile the `input.schema` and `output.schema` blocks—written in
  [Picoschema](https://google.github.io/dotprompt/reference/picoschema/)—into
  JSON Schema for runtime validation. Picoschema is a YAML‑friendly subset that
  ejects cleanly to JSON Schema. Schema detection rules:
  * If a schema contains a top-level `type` property, it is treated as pure JSON Schema
    and passed through directly to `JsonSchema.create`
  * Otherwise, if the schema contains PicoSchema features (optional fields with `?`,
    parenthetical types, comma-separated descriptions), it is treated as pure PicoSchema
    and compiled to JSON Schema
  * Mixed syntax (JSON Schema with PicoSchema features or vice versa) is not supported
    and will result in validation errors
* **Note:** YAML parsing should handle nested structures (e.g., `YamlMap` and `YamlList`) and convert them to `Map<String, dynamic>`.

### Template Engine
* **Custom Handlebars-compatible implementation** built from scratch in `lib/src/template/`
* **MUST achieve 100% spec compliance** with the [template spec](https://google.github.io/dotprompt/reference/template/)
* State machine-based parser in `template_machine.dart` for robust template processing
* Full support for Handlebars syntax including blocks, helpers, partials, and context variables
* Allow registration of custom helpers at runtime with full access to context and block content
* Comprehensive test suite ensuring every spec feature is validated

#### Implemented Features (v0.4.0)

**Core Template Syntax:**
* Variable interpolation: `{{variable}}`
* Nested property access: `{{object.property}}`
* HTML escaping by default: `{{variable}}` escapes, `{{{variable}}}` does not
* Escaped literal output: `\{{variable}}` renders as `{{variable}}`

**Built-in Helpers ([spec](https://google.github.io/dotprompt/reference/template/#built-in-helpers)):**
* `#if` conditional blocks with `else` support
* `#unless` inverted conditional blocks
* `#each` iteration over arrays and objects
  * `@index` - current iteration index
  * `@first` - true for first item
  * `@last` - true for last item
  * `@key` - property name when iterating objects
* `#with` context switching helper

**Dotprompt Helpers ([spec](https://google.github.io/dotprompt/reference/template/#dotprompt-helpers)):**
* `json` - serialize variables to JSON
* `role` - structural marker for multi-message prompts
* `history` - insert conversation history
* `media` - insert media content references
* `section` - structural marker for content positioning

**Custom Helpers ([spec](https://google.github.io/dotprompt/reference/template/#custom-helpers)):**
* Register via `registerHelper(name, function)`
* Support for positional arguments
* Support for named arguments
* Block helpers with `block()` and `inverse()` callbacks
* Full context access via `HelperInvocation.context`
* Error propagation for validation

**Context Variables ([spec](https://google.github.io/dotprompt/reference/template/#context-variables)):**
* `@root` - reference to root context from any depth
* `@metadata` - access to prompt configuration and messages
* `@metadata.prompt` - prompt front-matter
* `@metadata.messages` - conversation history
* `@metadata.docs` - document context
* Custom `@` variables via `context` parameter in `render()`

**Partials Support:**
* Abstract class `DotPromptPartialResolver` for resolving partial templates
* `PathPartialResolver` implementation for applications with `dart:io` access
* Searches for partials with naming conventions: `_partialName.prompt` or `_partialName.mustache`
* Supports multiple directory search paths
* Strips front-matter from `.prompt` partials automatically
* Web-compatible architecture (custom resolvers can be implemented for web platforms)
* Use syntax: `{{> partialName }}` in templates
* Partials inherit parent context
* Partials can be scoped: `{{> partialName scopedData }}`

#### Known Gaps for 100% Spec Compliance

The following Handlebars features from the spec are NOT yet implemented and MUST be addressed:
* Comment syntax `{{!-- --}}` (parser currently rejects `!` as invalid character)
* Whitespace control with `~` (e.g., `{{~#if}}`, `{{/if~}}`)
* Inline partials `{{#*inline "name"}}...{{/inline}}`
* Block parameters `{{#each items as |item index|}}`
* Hash arguments in partials `{{> partial name=value}}`
* `else if` chains - currently requires nested `#if`, spec may support `{{else if}}`
* Subexpressions `{{outer (inner)}}`
* `../` parent context navigation
* Literal segments `{{[special chars]}}`

**Test Coverage Requirements:**
* Every spec feature MUST have explicit test coverage
* Tests MUST validate both success and error cases
* Tests MUST cover edge cases (empty arrays, null values, missing properties, etc.)
* Tests MUST validate error messages are helpful and accurate

### Execution Model  
* Convert parsed prompt into a `GenerateRequest` object matching the [model
  interface](https://google.github.io/dotprompt/reference/model/) (messages,
  config, tools, output, context).  
* Support core config keys—`temperature`, `maxOutputTokens`, `topK`, `topP`,
  `stopSequences`—passed through unchanged to the underlying model.  
* Handle input validation and defaults in a specific order:
  1. Merge default values from input configuration with provided input data
  2. Input values take precedence over defaults when merging
  3. Validate the merged data against the compiled JSON Schema
  4. If validation fails, throw a `ValidationException` with detailed error messages
  5. After validation passes, use the merged data for template rendering
* Provide a simple call to load from files and strings. **As of 0.3.0, for web and wasm compatibility, use `DotPrompt.stream` instead of `DotPrompt.file`.** Example:

```dart
final greet = await DotPrompt.stream(
  File('prompts/greet.prompt').openRead(),
  name: 'prompts/greet.prompt',
  partialResolver: PathPartialResolver([Directory('prompts/partials')]), // optional, for partials support
);
final meta = greet.frontMatter; // the model info, settings, etc.
final prompt = greet.render({'name': 'Chris'}); // validates input and expands the prompt string

// TODO: use something like dartantic_ai to create an Agent and run the prompt
```

These calls perform schema validation, template rendering (with optional partials) and model settings.

### Typed Code Generation using a Builder (future)
* `build_runner` scans `*.prompt` files and emits a Dart class per prompt:  
  * constructor validates defaults  
  * `Future<OutputT> call(InputT input, {Context? context});`  
* Generated types derive from the JSON Schema via `json2dart`.  

### CLI (future)
`dotprompt <command>`  
* `lint` – schema, helper, and config validation  
* `render` – show final prompt given an input JSON  
* `run` – execute against a specified model backend  
* `test` – golden tests with input/output fixtures  
* `gen` – trigger build_runner outside IDEs  

#### 4 User Stories  
* **App dev**: "As a Flutter dev I drop a `.prompt` next to my widgets and call
  it with strongly‑typed Dart—no raw HTTP."
* **CI/CD engineer**: "I lint prompts in CI so schema drift is caught before
  prod."
* **Researcher**: "I rapidly A/B test temperature settings from the CLI without
  rewriting code."  

### Architecture & Dependencies
* **Packages**: `yaml`, `json_schema`, `path`, `collection`
  * `build_runner` (future), `source_gen` (future)
* **NO external template library** - custom implementation in `lib/src/template/`  

### References  
* [Dotprompt – Getting Started](https://google.github.io/dotprompt/getting-started/)  
* [Dotprompt – Front Matter Spec](https://google.github.io/dotprompt/reference/frontmatter/)  
* [Dotprompt – Picoschema Spec](https://google.github.io/dotprompt/reference/picoschema/)  
* [Dotprompt – Template Spec](https://google.github.io/dotprompt/reference/template/)  
* [Dotprompt – Model Spec](https://google.github.io/dotprompt/reference/model/)  
* [Dotprompt GitHub Repository](https://github.com/google/dotprompt)  
