import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'close_bracket_state.dart';
import 'get_attribute_state.dart';
import 'get_block_end_state.dart';

class GetBlockHelperState extends TemplateState {
  GetBlockHelperState({
    required this.helper,
    required this.symbol,
    required this.line,
  }) {
    methods = {'process': process, 'notify': notify};
  }
  final String helper;
  final List<dynamic> _attributes = [];
  final int symbol;
  final int line;

  String _body = '';

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == eos) {
      return TemplateResult(
        err: TemplateError(
          code: errorUnterminatedBlock,
          text: 'Unterminated block helper "$helper" at $line:$symbol',
        ),
      );
    } else if (charCode == closeBracket) {
      return TemplateResult(state: CloseBracketState());
    } else if (charCode == space) {
      return null;
    }

    return TemplateResult(
      state: GetAttributeState(),
      message: ProcessMessage(charCode: charCode),
    );
  }

  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifySecondCloseBracketFound:
        return TemplateResult(state: GetBlockEndState(blockName: helper));

      case notifyAttrResult:
        _attributes.add(msg.value);

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }

      case notifyBlockEndResult:
        _body = msg.value;

        return result(context);

      default:
        break;
    }

    return null;
  }

  TemplateResult result(TemplateContext context) {
    if (!context.callable(helper)) {
      return TemplateResult(
        err: TemplateError(
          code: errorHelperUnregistered,
          text: 'Helper "$helper" is unregistered',
        ),
      );
    }

    final result = TemplateResult();

    try {
      if (_attributes.isEmpty) {
        _attributes.add(context.data);
      }

      result.result = context.call(helper, _attributes, context.compile(_body));
      result.pop = true;
    } catch (e) {
      result.err = TemplateError(
        text: 'Helper "$helper" error: $e',
        code: errorCallingHelper,
      );
    }

    return result;
  }
}
