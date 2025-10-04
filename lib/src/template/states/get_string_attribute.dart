import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

/// State for processing string attributes (quoted strings).
class GetStringAttribute extends TemplateState {
  /// Creates a new string attribute state.
  GetStringAttribute({required this.quoteSymbol}) {
    methods = {'process': process};
  }

  /// The quote character used (single or double quote).
  final int quoteSymbol;
  String _value = '';
  bool _escape = false;

  /// Processes characters to build a string value, handling escape sequences.
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
                'Wrong attribute value character '
                '"${String.fromCharCode(charCode)}"',
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
