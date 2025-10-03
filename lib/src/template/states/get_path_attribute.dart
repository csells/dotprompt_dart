import '../notify_types.dart';
import '../template_context.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'get_path_state.dart';

class GetPathAttribute extends TemplateState {
  GetPathAttribute() {
    methods = {'init': init, 'notify': notify};
  }

  TemplateResult init(InitMessage msg, TemplateContext context) {
    final path = msg.value;

    return TemplateResult(state: GetPathState(path: path));
  }

  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyPathResult:
        // If the value is a Map, it's a named argument (key=value)
        // Otherwise it's a path that needs to be resolved from context
        final value = msg.value is Map ? msg.value : context.get(msg.value);
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
