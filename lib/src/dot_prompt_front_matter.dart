import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'input_output_config.dart';
import 'utility.dart';

/// Represents the properties parsed from a .prompt file's front matter.
class DotPromptFrontMatter {
  /// Creates a new instance of [DotPromptFrontMatter].
  DotPromptFrontMatter({
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
       input = InputConfig(
         schema: input?['schema'] as Map<String, dynamic>?,
         defaults: input?['default'] as Map<String, dynamic>?,
       ),
       output = OutputConfig(
         schema: output?['schema'] as Map<String, dynamic>?,
         format: output?['format'] as String?,
       ),
       metadata = metadata ?? {},
       ext = ext ?? {};

  /// Creates metadata from a YAML map.
  factory DotPromptFrontMatter.fromMap(Map<String, dynamic> map) {
    // Extract namespaced fields
    final ext = <String, dynamic>{};
    final data = Map<String, dynamic>.from(map);
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
          current[parts.last] = yamlToMap(value);
        } else if (value is List || value is YamlList) {
          current[parts.last] = yamlToList(value);
        } else {
          current[parts.last] = value;
        }
        return true;
      }
      return false;
    });

    // Strictly enforce the spec: only allow standard fields and namespaced
    // fields
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
        'Non-standard fields must be namespaced: '
        "'${nonStandardFields.join(', ')}'",
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

    // Validate input for extra/unexpected fields
    final allowedInputFields = {'schema', 'default'};
    final extraInputFields =
        input.keys.where((k) => !allowedInputFields.contains(k)).toList();
    if (extraInputFields.isNotEmpty) {
      throw FormatException(
        'Unexpected field(s) in input: ${extraInputFields.join(', ')}',
      );
    }

    return DotPromptFrontMatter(
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
  final InputConfig input;

  /// Output configuration including format and schema.
  final OutputConfig output;

  /// Arbitrary metadata to be used by code, tools, and libraries.
  final Map<String, dynamic> metadata;

  /// Extensions and namespaced fields.
  final Map<String, dynamic> ext;

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

  @override
  String toString() {
    final buffer = StringBuffer();
    const encoder = JsonEncoder.withIndent('  ');

    if (name != null) buffer.writeln('name: $name');
    if (variant != null) buffer.writeln('variant: $variant');
    if (model != null) buffer.writeln('model: $model');
    if (tools != null && tools!.isNotEmpty) {
      buffer.writeln('tools: [${tools!.join(', ')}]');
    }

    if (config.isNotEmpty) buffer.writeln('config: ${encoder.convert(config)}');
    if (input.schema != null || input.defaults.isNotEmpty) {
      buffer.writeln(
        // ignore: lines_longer_than_80_chars
        'input: ${encoder.convert({if (input.schema != null) 'schema': input.schema, if (input.defaults.isNotEmpty) 'default': input.defaults})}',
      );
    }
    if (output.schema != null || output.format != 'text') {
      buffer.writeln(
        // ignore: lines_longer_than_80_chars
        'output: ${encoder.convert({if (output.schema != null) 'schema': output.schema, if (output.format != 'text') 'format': output.format})}',
      );
    }
    if (metadata.isNotEmpty) {
      buffer.writeln('metadata: ${encoder.convert(metadata)}');
    }
    if (ext.isNotEmpty) buffer.writeln('extensions: ${encoder.convert(ext)}');

    return buffer.toString();
  }
}
