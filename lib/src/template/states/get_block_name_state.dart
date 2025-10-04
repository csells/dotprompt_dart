import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

/// State for processing block or helper names.
class GetBlockNameState extends TemplateState {
  /// Creates a new block name state.
  GetBlockNameState({this.name}) {
    methods = {'process': process};
  }

  /// The block or helper name being parsed.
  String? name;

  /// Processes characters to build the block or helper name.
  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    name ??= '';

    if (charCode == eos) {
      return TemplateResult(
        err: TemplateError(
          code: errorUnexpectedEndOfSource,
          text: 'block name error: unexpected end of source',
        ),
      );
    } else if (charCode >= 48 && charCode <= 57) {
      if (name!.isEmpty) {
        return TemplateResult(
          err: TemplateError(
            code: errorBlockNameWrongSpecified,
            text: 'Block name should not start with number character',
          ),
        );
      }

      name = name! + String.fromCharCode(charCode);
    } else if ((charCode >= 65 && charCode <= 90) ||
        (charCode >= 97 && charCode <= 122) ||
        charCode == 95) {
      name = name! + String.fromCharCode(charCode);
    } else if (charCode == space || charCode == closeBracket) {
      if (name!.isEmpty) {
        return TemplateResult(
          err: TemplateError(
            code: errorBlockNameWrongSpecified,
            text: 'Block name is empty',
          ),
        );
      }

      return TemplateResult(
        pop: true,
        message: NotifyMessage(
          type: notifyNameResult,
          value: name,
          charCode: charCode,
        ),
      );
    } else {
      return TemplateResult(
        err: TemplateError(
          code: errorNotAValidBlockNameChar,
          text:
              'Character "${String.fromCharCode(charCode)}" is not a valid '
              'in block name',
        ),
      );
    }

    return null;
  }
}
