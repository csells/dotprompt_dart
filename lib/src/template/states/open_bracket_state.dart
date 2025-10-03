import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

class OpenBracketState extends TemplateState {
  OpenBracketState() {
    methods = {'process': process};
  }

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

      default:
        res.err = TemplateError(
          code: errorCharNotAOpenBracket,
          text: 'Wrong character is given. Expected "{"',
        );
    }

    return res;
  }
}
