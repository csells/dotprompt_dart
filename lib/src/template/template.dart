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
  final Map<String, Function(List<dynamic>, Function?)> _helpers = {};
  final Map<String, dynamic> _options = {
    'ignoreUnregisteredHelperErrors': false,
  };

  /// Register a helper function
  void registerHelper(String name, Function(List<dynamic>, Function?) helper) {
    _helpers[name] = helper;
  }

  /// Set an option
  void setOption(String key, dynamic value) {
    _options[key] = value;
  }

  /// Render a template with the given data
  String render(String template, Map<String, dynamic> data) {
    final context = TemplateContext(data, _helpers, _options);

    final machine = TemplateMachine(template);
    return machine.run(context);
  }
}
