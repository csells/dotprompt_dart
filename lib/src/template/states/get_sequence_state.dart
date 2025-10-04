import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

/// State for determining the type of template sequence (helper, block, data,
/// etc.).
class GetSequenceState extends TemplateState {
  /// Creates the get sequence state.
  GetSequenceState() {
    methods = {'process': process};
  }

  /// Processes the first character after {{ to determine sequence type.
  TemplateResult process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    final res = TemplateResult();

    if (charCode == dollar) {
      res.pop = true;
      res.message = NotifyMessage(
        charCode: charCode,
        type: notifyIsHelperSequence,
      );
    } else if (charCode == openBracket) {
      res.pop = true;
      res.message = NotifyMessage(
        charCode: charCode,
        type: notifyIsUnescapedDataSequence,
      );
    } else if (charCode == sharp) {
      res.pop = true;
      res.message = NotifyMessage(
        charCode: charCode,
        type: notifyIsBlockSequence,
      );
    } else if (charCode == caret) {
      res.pop = true;
      res.message = NotifyMessage(
        charCode: charCode,
        type: notifyIsBlockSequence,
        value: '^', // Mark this as an inverted section
      );
    } else if (charCode == more) {
      res.pop = true;
      res.message = NotifyMessage(
        charCode: charCode,
        type: notifyIsPartialSequence,
      );
    } else if ((charCode >= 65 && charCode <= 90) ||
        (charCode >= 97 && charCode <= 122) ||
        charCode == dot ||
        charCode == 64) {
      // 64 is '@'
      res.pop = true;
      res.message = NotifyMessage(
        charCode: charCode,
        type: notifyIsDataSequence,
        value: String.fromCharCode(charCode),
      );
    } else {
      res.err = TemplateError(
        code: errorWrongSequenceCharacter,
        text: 'Wrong character "${String.fromCharCode(charCode)}" found',
      );
    }

    return res;
  }
}
