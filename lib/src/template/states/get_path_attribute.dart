import '../helper_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'get_path_state.dart';

/// State for processing path attributes and resolving their values.
class GetPathAttribute extends TemplateState {
  /// Creates a new path attribute state.
  GetPathAttribute() {
    methods = {'init': init, 'notify': notify};
  }

  /// Initializes by delegating to path state.
  TemplateResult init(InitMessage msg, TemplateContext context) {
    final path = msg.value;

    return TemplateResult(state: GetPathState(path: path));
  }

  /// Handles path notification and resolves the value from context.
  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyPathResult:
        dynamic value = msg.value;

        if (value is NamedArgument) {
          // pass through
        } else if (value is String) {
          // Check for boolean literals first
          if (value == 'true') {
            value = true;
          } else if (value == 'false') {
            value = false;
          } else {
            value = context.get(value);
          }
        }

        return TemplateResult(
          pop: true,
          message: NotifyMessage(
            charCode: msg.charCode,
            type: notifyAttrResult,
            value: value,
          ),
        );
    }

    return null;
  }
}
