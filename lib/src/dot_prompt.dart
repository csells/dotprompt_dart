import 'dart:async';
import 'dart:io';

import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Helper function to convert YamlMap/Map recursively to Map<String, dynamic>
dynamic _yamlToMap(dynamic yaml) {
  if (yaml is YamlMap || yaml is Map) {
    return Map<String, dynamic>.fromEntries(
      (yaml as Map).entries.map(
        (e) => MapEntry(e.key.toString(), _yamlToMap(e.value)),
      ),
    );
  } else if (yaml is YamlList || yaml is List) {
    return _yamlToList(yaml);
  } else {
    return yaml;
  }
}

/// Helper function to convert YamlList/List recursively to List<dynamic>
dynamic _yamlToList(dynamic yaml) {
  if (yaml is YamlList || yaml is List) {
    return (yaml as List).map(_yamlToMap).toList();
  } else {
    return yaml;
  }
}

/// Global settings for the dotprompt library.
class DotPromptSettings {
  /// Creates a new instance of [DotPromptSettings].
  const DotPromptSettings({
    this.defaultModel,
    this.defaultTemperature,
    this.defaultMaxOutputTokens,
  });

  /// Creates settings from a YAML map.
  factory DotPromptSettings.fromYaml(Map<String, dynamic> yaml) =>
      DotPromptSettings(
        defaultModel: yaml['model'] as String?,
        defaultTemperature: yaml['temperature'] as double?,
        defaultMaxOutputTokens: yaml['maxOutputTokens'] as int?,
      );

  /// The default model to use if not specified in the prompt file.
  final String? defaultModel;

  /// The default temperature to use if not specified in the prompt file.
  final double? defaultTemperature;

  /// The default max output tokens to use if not specified in the prompt file.
  final int? defaultMaxOutputTokens;

  /// The default settings instance.
  static const DotPromptSettings defaults = DotPromptSettings();
}

/// Represents the metadata parsed from a .prompt file's front matter.
class DotPromptMetadata {
  /// Creates a new instance of [DotPromptMetadata].
  DotPromptMetadata({
    this.name,
    this.variant,
    this.model,
    this.tools,
    Map<String, dynamic>? config,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? ext,
  }) : config = config ?? {},
       input = input ?? {},
       output = output ?? {},
       metadata = metadata ?? {},
       ext = ext ?? {};

  /// Creates metadata from a YAML map.
  factory DotPromptMetadata.fromMap(Map<String, dynamic> map) {
    // Convert any YamlMap values to regular Maps
    final convertedMap = _yamlToMap(map) as Map<String, dynamic>;

    // Extract namespaced fields
    final ext = <String, dynamic>{};
    final data = Map<String, dynamic>.from(convertedMap);
    data.removeWhere((key, value) {
      if (key.contains('.')) {
        final parts = key.split('.');
        var current = ext;
        for (var i = 0; i < parts.length - 1; i++) {
          current[parts[i]] = current[parts[i]] ?? <String, dynamic>{};
          current = current[parts[i]];
        }
        // Recursively convert value for ext
        if (value is Map || value is YamlMap) {
          current[parts.last] = _yamlToMap(value);
        } else if (value is List || value is YamlList) {
          current[parts.last] = _yamlToList(value);
        } else {
          current[parts.last] = value;
        }
        return true;
      }
      return false;
    });

    // Strictly enforce the spec: only allow standard fields and namespaced fields
    final standardFields = {
      'name',
      'variant',
      'model',
      'tools',
      'config',
      'input',
      'output',
      'metadata',
    };
    final nonStandardFields =
        data.keys.where((key) => !standardFields.contains(key)).toList();
    if (nonStandardFields.isNotEmpty) {
      throw FormatException(
        "Non-standard fields must be namespaced: '${nonStandardFields.join(', ')}'",
      );
    }

    Map<String, dynamic> ensureMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return Map<String, dynamic>.fromEntries(
          value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
        );
      }
      throw const FormatException(
        'input/output must be a map/object if present',
      );
    }

    final input = ensureMap(data['input']);
    final output = ensureMap(data['output']);

    return DotPromptMetadata(
      name: data['name'] as String?,
      variant: data['variant'] as String?,
      model: data['model'] as String?,
      tools: (data['tools'] as List?)?.cast<String>(),
      config: ensureMap(data['config']),
      input: input,
      output: output,
      metadata: ensureMap(data['metadata']),
      ext: ext,
    );
  }

  /// The name of the prompt.
  final String? name;

  /// The variant name for the prompt.
  final String? variant;

  /// The name of the model to use.
  final String? model;

  /// Names of tools to allow use of in this prompt.
  final List<String>? tools;

  /// Configuration to be passed to the model implementation.
  final Map<String, dynamic> config;

  /// Input configuration including defaults and schema.
  final Map<String, dynamic> input;

  /// Output configuration including format and schema.
  final Map<String, dynamic> output;

  /// Arbitrary metadata to be used by code, tools, and libraries.
  final Map<String, dynamic> metadata;

  /// Extensions and namespaced fields.
  final Map<String, dynamic> ext;

  /// Gets the input schema.
  Map<String, dynamic>? get inputSchema =>
      input['schema'] as Map<String, dynamic>?;

  /// Gets the output schema.
  Map<String, dynamic>? get outputSchema =>
      output['schema'] as Map<String, dynamic>?;

  /// Gets the input defaults.
  Map<String, dynamic>? get inputDefaults =>
      input['default'] as Map<String, dynamic>?;

  /// Gets the output format.
  String get outputFormat => output['format'] as String? ?? 'text';

  /// Gets a value from the metadata by key.
  dynamic operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'variant':
        return variant;
      case 'model':
        return model;
      case 'tools':
        return tools;
      case 'config':
        return config;
      case 'input':
        return input;
      case 'output':
        return output;
      case 'metadata':
        return metadata;
      default:
        return null;
    }
  }
}

/// The main class for working with .prompt files.
class DotPrompt {
  /// Loads a .prompt from a string content.
  factory DotPrompt.fromString(
    String content, {
    String? filename,
    DotPromptSettings settings = DotPromptSettings.defaults,
  }) {
    final parts = content.split('---');
    var metadata = <String, dynamic>{};
    var template = content;

    // If we have front matter (at least one --- delimiter)
    if (parts.length >= 2) {
      // Parse front matter
      final frontMatter = loadYaml(parts[1].trim());
      if (frontMatter is YamlMap) {
        // Convert YamlMap to Map<String, dynamic>
        metadata = _yamlToMap(frontMatter);
      }

      // Get template content (everything after the second ---)
      template = parts.length > 2 ? parts[2].trim() : '';
    }

    // Apply defaults from settings and filename
    metadata = _applyDefaults(metadata, filename, settings);

    return DotPrompt._(
      metadata: DotPromptMetadata.fromMap(metadata),
      template: template,
    );
  }
  DotPrompt._({required this.metadata, required this.template});

  /// Applies default values from settings and filename to the metadata.
  static Map<String, dynamic> _applyDefaults(
    Map<String, dynamic> metadata,
    String? filename,
    DotPromptSettings settings,
  ) {
    final result = Map<String, dynamic>.from(metadata);

    // Apply library settings defaults
    if (settings.defaultModel != null && !result.containsKey('model')) {
      result['model'] = settings.defaultModel;
    }
    if (settings.defaultTemperature != null &&
        !result.containsKey('temperature')) {
      result['temperature'] = settings.defaultTemperature;
    }
    if (settings.defaultMaxOutputTokens != null &&
        !result.containsKey('maxOutputTokens')) {
      result['maxOutputTokens'] = settings.defaultMaxOutputTokens;
    }

    // Apply filename-based defaults
    if (filename != null) {
      final basename = path.basenameWithoutExtension(filename);
      if (!result.containsKey('name')) {
        result['name'] = basename;
      }
    }

    return result;
  }

  /// The metadata parsed from the front matter of the prompt file.
  final DotPromptMetadata metadata;

  /// The template content of the prompt file.
  final String template;

  /// Loads a .prompt file from the given path.
  static Future<DotPrompt> fromFile(
    String filePath, {
    DotPromptSettings settings = DotPromptSettings.defaults,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    final content = await file.readAsString();
    return DotPrompt.fromString(
      content,
      filename: filePath,
      settings: settings,
    );
  }

  /// Renders the template with the given input data.
  String render(Map<String, dynamic> input) {
    final t = Template(template, htmlEscapeValues: false);
    return t.renderString(input);
  }
}
