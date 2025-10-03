import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

class GetStringAttribute extends TemplateState {
  GetStringAttribute({required this.quoteSymbol}) {
    methods = {'process': process};
  }
  final int quoteSymbol;
  String _value = '';
  bool _escape = false;

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (_escape) {
      _escape = false;
      _value += String.fromCharCode(charCode);
    } else {
      if (charCode == openBracket || charCode == closeBracket) {
        return TemplateResult(
          err: TemplateError(
            code: errorStringAttributeMalformed,
            text:
                'Wrong attribute value character "${String.fromCharCode(charCode)}"',
          ),
        );
      } else if (charCode == backSlash) {
        _escape = true;
      } else if (charCode == quoteSymbol) {
        return TemplateResult(
          pop: true,
          message: NotifyMessage(
            type: notifyAttrResult,
            value: _value,
            charCode: null,
          ),
        );
      } else {
        _value += String.fromCharCode(charCode);
      }
    }

    return null;
  }
}
