import 'built_in_helpers.dart';
import 'helper_types.dart';
import 'template_context.dart';
import 'template_machine.dart';

export 'characters_consts.dart';
export 'errors_types.dart';
export 'notify_types.dart';
export 'states/close_bracket_state.dart';
export 'states/get_attribute_state.dart';
export 'states/get_block_end_state.dart';
export 'states/get_block_helper_state.dart';
export 'states/get_block_name_state.dart';
export 'states/get_block_sequence_type_state.dart';
export 'states/get_condition_state.dart';
export 'states/get_data_state.dart';
export 'states/get_each_block_state.dart';
export 'states/get_helper_state.dart';
export 'states/get_if_block_state.dart';
export 'states/get_if_condition_state.dart';
export 'states/get_number_attribute.dart';
export 'states/get_partial_state.dart';
export 'states/get_path_attribute.dart';
export 'states/get_path_state.dart';
export 'states/get_sequence_state.dart';
export 'states/get_string_attribute.dart';
export 'states/get_with_block_state.dart';
export 'states/open_bracket_state.dart';
export 'states/root_state.dart';
export 'template_context.dart';
export 'template_error.dart';
export 'template_machine.dart';
export 'template_messages.dart';
export 'template_result.dart';
export 'template_state.dart';

/// Template is a Handlebars-like template engine for Dart.
class Template {
  /// Creates a template with optional partial resolver.
  Template(
    this.source, {
    bool htmlEscapeValues = true,
    String? Function(String)? partialResolver,
  }) : _htmlEscapeValues = htmlEscapeValues,
       _partialResolver = partialResolver {
    // Register built-in helpers
    final builtInHelpers = getBuiltInHelpers();
    for (final entry in builtInHelpers.entries) {
      _helpers[entry.key] = entry.value;
    }
  }

  /// The template source.
  final String source;

  final bool _htmlEscapeValues;
  final String? Function(String)? _partialResolver;
  final Map<String, TemplateHelper> _helpers = {};
  final Map<String, dynamic> _options = {
    'ignoreUnregisteredHelperErrors': false,
  };

  /// Register a helper function
  void registerHelper(String name, TemplateHelper helper) {
    _helpers[name] = helper;
  }

  /// Set an option
  void setOption(String key, dynamic value) {
    _options[key] = value;
  }

  /// Render a template with the given data
  String render(
    String template,
    Map<String, dynamic> data, {
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? contextVariables,
  }) {
    // Create context with partial resolver
    final renderOptions = Map<String, dynamic>.from(_options)
      ..['htmlEscapeValues'] = _htmlEscapeValues;

    final sharedAt = <String, dynamic>{
      '@root': data,
      '@metadata': metadata ?? <String, dynamic>{},
    };

    if (contextVariables != null) {
      for (final entry in contextVariables.entries) {
        final key = entry.key.startsWith('@') ? entry.key : '@${entry.key}';
        sharedAt[key] = entry.value;
      }
    }

    final context = TemplateContext(
      value: data,
      helpers: _helpers,
      options: renderOptions,
      partialResolver: _partialResolver,
      metadata: metadata,
      sharedAtVariables: sharedAt,
      rootValue: data,
    );

    final machine = TemplateMachine(template);
    return machine.run(context);
  }

  /// Render the template using its source with the given data
  String renderString(
    Map<String, dynamic> data, {
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? contextVariables,
  }) => render(
    source,
    data,
    metadata: metadata,
    contextVariables: contextVariables,
  );
}
