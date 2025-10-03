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

class GetEachBlockState extends TemplateState {
  GetEachBlockState({required this.symbol, required this.line}) {
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
          text: 'Unterminated "EACH" block at $line:$symbol',
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

  TemplateResult notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyPathResult:
        _path = msg.value;

        return TemplateResult(message: ProcessMessage(charCode: msg.charCode!));

      case notifySecondCloseBracketFound:
        return TemplateResult(state: GetBlockEndState(blockName: 'each'));

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
  }

  TemplateResult result(TemplateContext context) {
    final result = TemplateResult();

    if (_path.isEmpty) {
      result.err = TemplateError(
        text: '"EACH" block requires path as parameter',
        code: errorPathNotSpecified,
      );
    } else {
      try {
        final data = context.get(_path);

        if (data != null) {
          if (data is List || data is Map) {
            final fn = context.compile(_body);

            var res = '';

            if (fn != null) {
              if (data is List) {
                for (final item in data) {
                  res += fn(item);
                }
              } else {
                data.forEach((key, item) {
                  res += fn(item);
                });
              }
            }

            return TemplateResult(result: res, pop: true);
          } else {
            result.err = TemplateError(
              text: '"each" block data should have "List" or "Map" type',
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
