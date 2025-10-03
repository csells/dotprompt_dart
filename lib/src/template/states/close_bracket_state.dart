import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

class CloseBracketState extends TemplateState {
  CloseBracketState() {
    methods = {'process': process};
  }

  TemplateResult process(ProcessMessage msg, TemplateContext context) {
    final res = TemplateResult();

    final charCode = msg.charCode;

    switch (charCode) {
      case closeBracket:
        res.pop = true;
        res.message = NotifyMessage(type: notifySecondCloseBracketFound);
      default:
        res.err = TemplateError(
          code: errorChartNotACloseBracket,
          text: 'Wrong character is given. Expected "}"',
        );
    }

    return res;
  }
}
