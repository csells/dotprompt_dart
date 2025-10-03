import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'close_bracket_state.dart';
import 'get_block_end_state.dart';
import 'get_if_condition_state.dart';

class GetIfBlockState extends TemplateState {
  GetIfBlockState({required this.symbol, required this.line}) {
    methods = {'process': process, 'notify': notify};
  }
  final int symbol;
  final int line;

  bool _res = false;
  String _body = '';

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
        return TemplateResult(state: GetBlockEndState(blockName: 'if'));

      case notifyBlockEndResult:
        _body = msg.value;
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

    if (_res) {
      try {
        final fn = context.compile(_body);

        if (fn != null) {
          res = fn(context.data);
        }
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
