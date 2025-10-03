import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

class GetConditionState extends TemplateState {
  GetConditionState() {
    methods = {'process': process};
  }
  String _condition = '';

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == eos) {
      return TemplateResult(
        err: TemplateError(
          code: errorUnexpectedEndOfSource,
          text: 'IF condition error: unexpected end of source',
        ),
      );
    } else if (charCode == more ||
        charCode == less ||
        charCode == equal ||
        charCode == exclMark) {
      _condition += String.fromCharCode(charCode);
      return null;
    } else if (charCode == closeBracket || charCode == space) {
      if (_condition.isEmpty) {
        return TemplateResult(
          err: TemplateError(
            code: errorIfBlockConditionMalformed,
            text: 'If block condition should not be empty',
          ),
        );
      } else if (_condition.length > 2 ||
          !['==', '!=', '<', '>', '<=', '>='].contains(_condition)) {
        return TemplateResult(
          err: TemplateError(
            code: errorIfBlockConditionMalformed,
            text: 'If block condition malformed: "$_condition"',
          ),
        );
      } else {
        return TemplateResult(
          pop: true,
          message: NotifyMessage(
            type: notifyConditionResult,
            value: _condition,
            charCode: charCode,
          ),
        );
      }
    }

    return TemplateResult(
      err: TemplateError(
        code: errorGettingAttribute,
        text:
            'Wrong condition character "${String.fromCharCode(charCode)}" ($charCode)',
      ),
    );
  }
}
