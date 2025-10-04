/// dotprompt_dart is the Dart implementation of the dotprompt specification,
/// which provides an executable prompt template file format for Generative AI.
library;

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'dot_prompt_front_matter.dart';
import 'partial_resolver.dart';
import 'template/helper_types.dart';
import 'template/template.dart';
import 'utility.dart';

/// Exception thrown when input data fails schema validation.
class ValidationException implements Exception {
  /// Creates a validation exception with an error message and list of
  /// validation errors.
  ValidationException(this.message, this.errors);

  /// The error message describing the validation failure.
  final String message;

  /// The list of specific validation error messages.
  final List<String> errors;

  @override
  String toString() => '$message: ${errors.join(', ')}';
}

/// The main class for working with .prompt files.
class DotPrompt {
  /// Loads a .prompt from a string content.
  ///
  /// Takes an optional [partialResolver] which can resolve dotprompt partial
  /// files. Supply a path-based partial resolver in applications that can use
  /// dart:io.
  factory DotPrompt(
    String content, {
    Map<String, dynamic>? defaults,
    DotPromptPartialResolver? partialResolver,
  }) {
    final parts = content.split('---');
    var front = <String, dynamic>{};
    var template = content;

    // If we have front matter (at least one --- delimiter)
    if (parts.length >= 2) {
      // Parse front matter
      final frontMatter = loadYaml(parts[1].trim());
      if (frontMatter is YamlMap) {
        // Convert YamlMap to Map<String, dynamic>
        front = yamlToMap(frontMatter);
      }

      // Get template content (everything after the second ---)
      template = parts.length > 2 ? parts[2].trim() : '';
    }

    // Apply defaults from filename
    front = _applyDefaults(frontMatter: front, defaults: defaults);

    return DotPrompt._parts(
      frontMatter: DotPromptFrontMatter.fromMap(front),
      template: template,
      partialResolver: partialResolver,
    );
  }

  DotPrompt._parts({
    required this.frontMatter,
    required String template,
    DotPromptPartialResolver? partialResolver,
  }) : _template = Template(
         template,
         htmlEscapeValues: true,
         partialResolver: partialResolver?.resolve,
       );

  /// Loads a .prompt file from a stream.
  static Future<DotPrompt> stream(
    Stream<List<int>> stream, {
    String? name,
    Map<String, dynamic>? defaults,
    DotPromptPartialResolver? partialResolver,
  }) async {
    final bytes = await stream.reduce((a, b) => a + b);
    final content = utf8.decode(bytes);

    // Apply name-based defaults
    if (defaults != null && !defaults.containsKey('name')) {
      final basename = path.basenameWithoutExtension(name ?? '');
      defaults = Map.from(defaults);
      defaults['name'] = basename;
    }

    return DotPrompt(
      content,
      defaults: defaults,
      partialResolver: partialResolver,
    );
  }

  // Applies default values from default settings.
  static Map<String, dynamic> _applyDefaults({
    required Map<String, dynamic> frontMatter,
    Map<String, dynamic>? defaults,
  }) {
    final result = Map<String, dynamic>.from(frontMatter);

    if (defaults != null) {
      // Only add keys from defaults that don't already exist in front matter
      defaults.forEach((key, value) {
        if (!result.containsKey(key)) result[key] = value;
      });
    }

    return result;
  }

  /// The properties parsed from the front matter of the prompt file.
  final DotPromptFrontMatter frontMatter;

  /// The template content of the prompt file.
  String get template => _template.source;

  final Template _template;

  /// Registers a custom helper available to this prompt instance.
  void registerHelper(String name, TemplateHelper helper) {
    _template.registerHelper(name, helper);
  }

  /// Renders the template with the given input data.
  /// Throws [ValidationException] if the input data fails schema validation.
  String render({
    Map<String, dynamic> input = const {},
    List<Map<String, dynamic>> messages = const [],
    dynamic docs,
    Map<String, dynamic>? context,
  }) {
    // Merge defaults with input, letting input override defaults
    final mergedInput = Map<String, dynamic>.from(frontMatter.input.defaults);
    mergedInput.addAll(input);

    // Validate merged input against schema if one exists
    if (frontMatter.input.schema != null) {
      final results = frontMatter.input.schema!.validate(mergedInput);
      if (!results.isValid) {
        throw ValidationException(
          'Input data failed schema validation',
          results.errors.map((e) => e.message).toList(),
        );
      }
    }

    final metadata = {
      'prompt': frontMatter.toMetadata(),
      'docs': docs ?? frontMatter.metadata['docs'] ?? const [],
      'messages': List<Map<String, dynamic>>.from(messages),
    };

    final atVariables = <String, dynamic>{};
    if (context != null) {
      for (final entry in context.entries) {
        final key = entry.key.startsWith('@') ? entry.key : '@${entry.key}';
        atVariables[key] = entry.value;
      }
    }

    return _template.renderString(
      mergedInput,
      metadata: metadata,
      contextVariables: atVariables,
    );
  }
}
