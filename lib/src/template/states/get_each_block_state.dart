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
import 'get_path_state.dart';

/// State for processing each blocks ({{#each items}}).
class GetEachBlockState extends TemplateState {
  /// Creates a new each block state.
  GetEachBlockState({required this.symbol, required this.line}) {
    methods = {'process': process, 'notify': notify};
  }

  /// The column position where the block started.
  final int symbol;

  /// The line number where the block started.
  final int line;

  String _path = '';
  String _body = '';

  /// Processes characters to collect the path for iteration.
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

  /// Handles notifications for path and block end.
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
                'State "GetEachBlockState" does not support notifies of '
                'type ${msg.type}',
          ),
        );
    }
  }

  /// Executes the each block iteration and returns the result.
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
            final buffer = StringBuffer();

            if (data is List) {
              for (var i = 0; i < data.length; i++) {
                final item = data[i];
                final locals = {
                  '@index': i,
                  '@first': i == 0,
                  '@last': i == data.length - 1,
                };

                final itemContext = context.child(item, locals: locals);
                final machine = TemplateMachine(_body);
                buffer.write(machine.run(itemContext));
              }
            } else {
              var index = 0;
              // ignore: avoid_dynamic_calls
              final keys = data.keys.toList();
              for (final key in keys) {
                // ignore: avoid_dynamic_calls
                final item = data[key];
                final locals = {
                  '@key': key,
                  '@index': index,
                  '@first': index == 0,
                  // ignore: avoid_dynamic_calls
                  '@last': index == keys.length - 1,
                };

                final itemContext = context.child(item, locals: locals);
                final machine = TemplateMachine(_body);
                buffer.write(machine.run(itemContext));
                index++;
              }
            }

            return TemplateResult(result: buffer.toString(), pop: true);
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
      } on Exception catch (e) {
        result.err = TemplateError(
          text: e.toString(),
          code: errorCallingHelper,
        );
      }
    }

    return result;
  }
}
