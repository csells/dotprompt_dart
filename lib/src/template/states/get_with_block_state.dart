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
import 'get_path_state.dart';

class GetWithBlockState extends TemplateState {
  GetWithBlockState({required this.symbol, required this.line}) {
    methods = {'process': process, 'notify': notify};
  }
  final int symbol;
  final int line;

  String _path = '';
  String _body = '';

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == eos) {
      return TemplateResult(
        err: TemplateError(
          code: errorUnterminatedBlock,
          text: 'Unterminated "WITH" block at $line:$symbol',
        ),
      );
    } else if (charCode == closeBracket) {
      return TemplateResult(state: CloseBracketState());
    } else if (charCode == space) {
      return null;
    }

    return TemplateResult(
      state: GetPathState(),
      message: ProcessMessage(charCode: charCode),
    );
  }

  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyPathResult:
        _path = msg.value;
        return TemplateResult(message: ProcessMessage(charCode: msg.charCode!));

      case notifySecondCloseBracketFound:
        return TemplateResult(state: GetBlockEndState(blockName: 'with'));

      case notifyBlockEndResult:
        _body = msg.value;
        return result(context);
    }

    return null;
  }

  TemplateResult result(TemplateContext context) {
    final result = TemplateResult();

    if (_path.isEmpty) {
      result.err = TemplateError(
        text: 'With block required path to context data',
        code: errorPathNotSpecified,
      );
    } else {
      try {
        final data = context.get(_path);

        if (data != null) {
          if (data is Map) {
            final fn = context.compile(_body);

            return TemplateResult(
              result: fn != null ? fn(data) : '',
              pop: true,
            );
          } else {
            result.err = TemplateError(
              text: '"With" block data should have "Map" type',
              code: errorWithDataMalformed,
            );
          }
        } else {
          result.err = TemplateError(
            text: 'Can\'t get data from context by path "$_path"',
            code: errorPathWrongSpecified,
          );
        }
      } catch (e) {
        result.err = TemplateError(
          text: e.toString(),
          code: errorCallingHelper,
        );
      }
    }

    return result;
  }
}
