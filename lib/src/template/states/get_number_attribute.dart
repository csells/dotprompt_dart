import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

class GetNumberAttribute extends TemplateState {
  GetNumberAttribute({this.value}) {
    methods = {'process': process};
  }
  String? value;

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    value ??= '';

    if (charCode == closeBracket || charCode == space) {
      return TemplateResult(
        pop: true,
        message: NotifyMessage(
          charCode: charCode,
          type: notifyAttrResult,
          value: num.parse(value!),
        ),
      );
    } else if (charCode == dot) {
      if (value!.indexOf(String.fromCharCode(dot)) > 0) {
        return TemplateResult(
          err: TemplateError(
            text: 'Duplicate number delimiter',
            code: errorNumberAttributeMalformed,
          ),
        );
      }

      value = value! + String.fromCharCode(charCode);
    } else if (charCode >= 48 && charCode <= 57) {
      value = value! + String.fromCharCode(charCode);
    } else {
      return TemplateResult(
        err: TemplateError(
          text: 'Number attribute malformed',
          code: errorNumberAttributeMalformed,
        ),
      );
    }

    return null;
  }
}
