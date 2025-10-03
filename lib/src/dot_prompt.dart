/// @docImport 'path_partial_resolver.dart';
library;

import 'dart:async';
import 'dart:convert';

import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'dot_prompt_front_matter.dart';
import 'partial_resolver.dart';
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
  /// files. Supply a [PathPartialResolver] in applications that can use
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
         htmlEscapeValues: false,
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

  /// Renders the template with the given input data.
  /// Throws [ValidationException] if the input data fails schema validation.
  String render([Map<String, dynamic> input = const {}]) {
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

    return _template.renderString(mergedInput);
  }
}
