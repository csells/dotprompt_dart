import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_machine.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'close_bracket_state.dart';
import 'get_block_end_state.dart';
import 'get_if_condition_state.dart';

class GetIfBlockState extends TemplateState {
  GetIfBlockState({
    required this.symbol,
    required this.line,
    this.inverted = false,
    this.blockName = 'if',
  }) {
    methods = {'process': process, 'notify': notify};
  }
  final int symbol;
  final int line;
  final bool inverted;
  final String blockName;

  bool _res = false;
  String _body = '';
  String _elseBody = '';

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == eos) {
      return TemplateResult(
        err: TemplateError(
          code: errorUnterminatedBlock,
          text: 'Unterminated "IF" block at $line:$symbol',
        ),
      );
    } else if (charCode == space) {
      return null;
    } else if (charCode == closeBracket) {
      return TemplateResult(state: CloseBracketState());
    }

    return TemplateResult(
      state: GetIfConditionState(),
      message: ProcessMessage(charCode: charCode),
    );
  }

  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyConditionResult:
        _res = msg.value ?? false;

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }

      case notifySecondCloseBracketFound:
        return TemplateResult(state: GetBlockEndState(blockName: blockName));

      case notifyBlockEndResult:
        final fullBody = msg.value as String;
        // Check if there's an {{else}} tag - split on it if found
        final elseIndex = fullBody.indexOf('{{else}}');
        if (elseIndex != -1) {
          _body = fullBody.substring(0, elseIndex);
          _elseBody = fullBody.substring(elseIndex + 8); // Skip '{{else}}'
        } else {
          _body = fullBody;
        }
        return result(context);

      default:
        return TemplateResult(
          err: TemplateError(
            code: errorUnsupportedNotify,
            text:
                'State "$runtimeType" does not support notifies of type ${msg.type}',
          ),
        );
    }

    return null;
  }

  TemplateResult result(TemplateContext context) {
    var res = '';

    // Apply inverted logic if this is an 'unless' block
    final shouldRender = inverted ? !_res : _res;

    if (shouldRender) {
      try {
        final machine = TemplateMachine(_body);
        res = machine.run(context);
      } catch (e) {
        return TemplateResult(
          err: TemplateError(
            code: errorIfBlockMalformed,
            text: 'If block error: $e',
          ),
        );
      }
    } else if (_elseBody.isNotEmpty) {
      // Render else body if condition is false
      try {
        final machine = TemplateMachine(_elseBody);
        res = machine.run(context);
      } catch (e) {
        return TemplateResult(
          err: TemplateError(
            code: errorIfBlockMalformed,
            text: 'If block error: $e',
          ),
        );
      }
    }

    return TemplateResult(pop: true, result: res);
  }
}
