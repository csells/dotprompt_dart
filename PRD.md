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
* Use a Handlebars‑compatible renderer and expose the Dotprompt‑required
  helpers: `json`, `role`, `history`, `media`, `section`, matching the [template
  spec](https://google.github.io/dotprompt/reference/template/).
* The content can be parsed using the
  [mustache_template](https://pub.dev/packages/mustache_template) package.
* Allow registration of custom helpers at runtime; retain full fidelity with
  Handlebars blocks and partials.  

### Execution Model  
* Convert parsed prompt into a `GenerateRequest` object matching the [model
  interface](https://google.github.io/dotprompt/reference/model/) (messages,
  config, tools, output, context).  
* Support core config keys—`temperature`, `maxOutputTokens`, `topK`, `topP`,
  `stopSequences`—passed through unchanged to the underlying model.  
* Provide a simple call to load from files and strings, e.g. here for files:

```dart
final greet = await DotPrompt.fromFile('prompts/greet.prompt');
final meta = greet.metadata; // the model info, settings, etc.
final prompt = greet.render({'name': 'Chris'}); // the expanded prompt string

// TODO: use something like dartantic_ai to create an Agent and run the prompt
```  

These calls performs schema validation, template rendering and model settings.

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
* **Packages**: `yaml`, `json_schema`, `fbh_front_matter`, `mustache_template`,
  `build_runner` (future), `source_gen` (future)  

### References  
* [Dotprompt – Getting Started](https://google.github.io/dotprompt/getting-started/)  
* [Dotprompt – Front Matter Spec](https://google.github.io/dotprompt/reference/frontmatter/)  
* [Dotprompt – Picoschema Spec](https://google.github.io/dotprompt/reference/picoschema/)  
* [Dotprompt – Template Spec](https://google.github.io/dotprompt/reference/template/)  
* [Dotprompt – Model Spec](https://google.github.io/dotprompt/reference/model/)  
* [Dotprompt GitHub Repository](https://github.com/google/dotprompt)  
