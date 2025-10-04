import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

/// State for processing numeric attributes.
class GetNumberAttribute extends TemplateState {
  /// Creates a new number attribute state.
  GetNumberAttribute({this.value}) {
    methods = {'process': process};
  }

  /// The numeric value being parsed.
  String? value;

  /// Processes characters to build a numeric value.
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
