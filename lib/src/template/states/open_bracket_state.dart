import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

/// State for processing the first open bracket of an expression ({{).
class OpenBracketState extends TemplateState {
  /// Creates the open bracket state.
  OpenBracketState() {
    methods = {'process': process};
  }

  /// Processes the second open bracket to start an expression.
  TemplateResult process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;
    final res = TemplateResult();

    switch (charCode) {
      case openBracket:
        res.pop = true;
        res.message = NotifyMessage(
          charCode: charCode,
          type: notifySecondOpenBracketFound,
        );
        return res;
      default:
        res.err = TemplateError(
          code: errorCharNotAOpenBracket,
          text: 'Wrong character is given. Expected "{"',
        );
        return res;
    }
  }
}
