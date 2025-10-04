import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';

/// State for processing closing brackets (}}) of an expression.
class CloseBracketState extends TemplateState {
  /// Creates a close bracket state expecting [expectedBraces] closing braces.
  CloseBracketState({this.expectedBraces = 2}) {
    methods = {'process': process};
    _remaining = expectedBraces - 1;
  }

  /// The number of closing braces expected.
  final int expectedBraces;

  late int _remaining;

  /// Processes closing brackets to end an expression.
  TemplateResult process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == closeBracket) {
      if (_remaining <= 0) {
        return TemplateResult(
          err: TemplateError(
            code: errorChartNotACloseBracket,
            text: 'Unexpected extra closing brace',
          ),
        );
      }

      _remaining--;

      if (_remaining == 0) {
        return TemplateResult(
          pop: true,
          message: NotifyMessage(type: notifySecondCloseBracketFound),
        );
      }

      return TemplateResult();
    }

    return TemplateResult(
      err: TemplateError(
        code: errorChartNotACloseBracket,
        text: 'Wrong character is given. Expected "}"',
      ),
    );
  }
}
