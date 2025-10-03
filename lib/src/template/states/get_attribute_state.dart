import '../characters_consts.dart';
import '../errors_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'get_number_attribute.dart';
import 'get_path_attribute.dart';
import 'get_string_attribute.dart';

class GetAttributeState extends TemplateState {
  GetAttributeState() {
    methods = {'process': process};
  }

  TemplateResult process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == quote || charCode == singleQuote) {
      return TemplateResult(
        pop: true,
        state: GetStringAttribute(quoteSymbol: charCode),
      );
    } else if (charCode >= 48 && charCode <= 57) {
      return TemplateResult(
        pop: true,
        state: GetNumberAttribute(),
        message: ProcessMessage(charCode: charCode),
      );
    } else if ((charCode >= 65 && charCode <= 90) ||
        (charCode >= 97 && charCode <= 122) ||
        charCode == 95) {
      return TemplateResult(
        pop: true,
        message: InitMessage(value: String.fromCharCode(charCode)),
        state: GetPathAttribute(),
      );
    }
    return TemplateResult(
      err: TemplateError(
        code: errorGettingAttribute,
        text: 'Wrong attribute character "${String.fromCharCode(charCode)}"',
      ),
    );
  }
}
