import '../characters_consts.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'get_block_sequence_type_state.dart';
import 'get_data_state.dart';
import 'get_helper_state.dart';
import 'get_partial_state.dart';
import 'get_sequence_state.dart';
import 'open_bracket_state.dart';

/// Root state for processing template text outside of expressions.
class RootState extends TemplateState {
  /// Creates the root state.
  RootState() {
    methods = {'process': process, 'notify': notify};
  }

  /// Whether the next character is escaped.
  bool escape = false;

  /// Whether to skip expression parsing for one character.
  bool skipExpressionOnce = false;

  /// Processes characters and detects expression start markers.
  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final res = TemplateResult();
    final charCode = msg.charCode;

    if (charCode == eos) return null;

    if (skipExpressionOnce) {
      skipExpressionOnce = false;
      res.result = String.fromCharCode(charCode);
      return res;
    }

    if (escape) {
      escape = false;

      if (charCode == openBracket) {
        skipExpressionOnce = true;
      }

      res.result = String.fromCharCode(charCode);
      return res;
    }

    switch (charCode) {
      case backSlash:
        escape = true;
        return res;
      case openBracket:
        res.state = OpenBracketState();
        return res;
      default:
        res.result = String.fromCharCode(charCode);
        return res;
    }
  }

  /// Handles notifications from child states to transition to appropriate
  /// states.
  TemplateResult notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifySecondOpenBracketFound:
        return TemplateResult(state: GetSequenceState());
      case notifyIsHelperSequence:
        return TemplateResult(state: GetHelperState(), message: InitMessage());
      case notifyIsBlockSequence:
        final inverted = msg.value == '^';
        return TemplateResult(
          state: GetBlockSequenceTypeState(inverted: inverted),
          message: InitMessage(),
        );
      case notifyIsPartialSequence:
        return TemplateResult(state: GetPartialState());
      case notifyIsDataSequence:
        final shouldEscape = context.opt('htmlEscapeValues') != false;
        return TemplateResult(
          state: GetDataState(escapeValues: shouldEscape),
          message: InitMessage(value: msg.value),
        );
      case notifyIsUnescapedDataSequence:
        return TemplateResult(
          state: GetDataState(escapeValues: false, closingBraces: 3),
          message: InitMessage(value: msg.value),
        );
      default:
        return TemplateResult();
    }
  }
}
