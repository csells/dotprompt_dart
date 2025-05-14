import 'dart:async';
import 'dart:io';

import 'package:mustache_template/mustache_template.dart';
import 'package:yaml/yaml.dart';

/// The main class for working with .prompt files.
class DotPrompt {
  DotPrompt._({
    required this.metadata,
    required this.template,
    this.inputSchema,
    this.outputSchema,
  });

  /// Loads a .prompt from a string content.
  factory DotPrompt.fromString(String content) {
    final parts = content.split('---');

    if (parts.length < 2) {
      throw const FormatException(
        'Invalid prompt file format: missing front matter delimiter',
      );
    }

    // Parse front matter
    final frontMatter = loadYaml(parts[1].trim());
    if (frontMatter is! YamlMap) {
      throw const FormatException(
        'Invalid front matter: must be a YAML object',
      );
    }

    // Convert YamlMap to Map<String, dynamic>
    final Map<String, dynamic> metadata = _yamlToMap(frontMatter);

    // Extract schemas from front matter
    final inputSchema = metadata['input.schema'] as Map<String, dynamic>?;
    final outputSchema = metadata['output.schema'] as Map<String, dynamic>?;

    // Get template content (everything after the second ---)
    final template = parts.length > 2 ? parts[2].trim() : '';

    return DotPrompt._(
      metadata: metadata,
      template: template,
      inputSchema: inputSchema,
      outputSchema: outputSchema,
    );
  }

  /// The metadata parsed from the front matter of the prompt file.
  final Map<String, dynamic> metadata;

  /// The template content of the prompt file.
  final String template;

  /// The input schema for validating input data.
  final Map<String, dynamic>? inputSchema;

  /// The output schema for validating output data.
  final Map<String, dynamic>? outputSchema;

  /// Helper function to convert `YamlMap` to `Map<String, dynamic>`
  /// recursively.
  static dynamic _yamlToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return Map<String, dynamic>.fromEntries(
        yaml.entries.map(
          (e) => MapEntry(e.key.toString(), _yamlToMap(e.value)),
        ),
      );
    } else if (yaml is YamlList) {
      return yaml.map(_yamlToMap).toList();
    } else {
      return yaml;
    }
  }

  /// Loads a .prompt file from the given path.
  static Future<DotPrompt> fromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    final content = await file.readAsString();
    return DotPrompt.fromString(content);
  }

  /// Renders the template with the given input data.
  String render(Map<String, dynamic> input) {
    final t = Template(template, htmlEscapeValues: false);
    return t.renderString(input);
  }
}
