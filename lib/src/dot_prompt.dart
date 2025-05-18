import 'dart:async';
import 'dart:io';

import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'dot_prompt_front_matter.dart';
import 'utility.dart';

/// The main class for working with .prompt files.
class DotPrompt {
  DotPrompt._({required this.frontMatter, required String template})
    : _template = Template(template, htmlEscapeValues: false);

  /// Loads a .prompt from a string content.
  factory DotPrompt.fromString(
    String content, {
    Map<String, dynamic>? defaults,
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

    return DotPrompt._(
      frontMatter: DotPromptFrontMatter.fromMap(front),
      template: template,
    );
  }

  /// Loads a .prompt file from the given path.
  static Future<DotPrompt> fromFile(
    String filePath, {
    Map<String, dynamic>? defaults,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    final content = await file.readAsString();

    // Apply filename-based defaults
    if (defaults != null && !defaults.containsKey('name')) {
      final basename = path.basenameWithoutExtension(filePath);
      defaults = Map.from(defaults);
      defaults['name'] = basename;
    }

    return DotPrompt.fromString(content, defaults: defaults);
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
  String render(Map<String, dynamic> input) => _template.renderString(input);
}
