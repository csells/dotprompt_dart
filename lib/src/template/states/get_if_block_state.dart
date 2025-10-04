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

/// State for processing if/unless blocks ({{#if condition}}).
class GetIfBlockState extends TemplateState {
  /// Creates a new if block state.
  GetIfBlockState({
    required this.symbol,
    required this.line,
    this.inverted = false,
    this.blockName = 'if',
  }) {
    methods = {'process': process, 'notify': notify};
  }

  /// The column position where the block started.
  final int symbol;

  /// The line number where the block started.
  final int line;

  /// Whether this is an inverted block (unless).
  final bool inverted;

  /// The block name (if or unless).
  final String blockName;

  bool _res = false;
  String _body = '';
  String _elseBody = '';

  /// Processes characters to collect the condition.
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

  /// Handles notifications for condition and block end.
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
        final split = _splitElse(msg.value as String);
        _body = split.key;
        _elseBody = split.value ?? '';
        return result(context);

      default:
        return TemplateResult(
          err: TemplateError(
            code: errorUnsupportedNotify,
            text:
                'State "GetIfBlockState" does not support notifies of '
                'type ${msg.type}',
          ),
        );
    }

    return null;
  }

  /// Evaluates the condition and renders the appropriate block.
  TemplateResult result(TemplateContext context) {
    var res = '';

    // Apply inverted logic if this is an 'unless' block
    final shouldRender = inverted ? !_res : _res;

    if (shouldRender) {
      try {
        final machine = TemplateMachine(_body);
        res = machine.run(context);
      } on Exception catch (e) {
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
      } on Exception catch (e) {
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

  MapEntry<String, String?> _splitElse(String source) {
    var depth = 0;
    var index = 0;

    while (index < source.length) {
      final open = source.indexOf('{{', index);
      if (open == -1) break;
      final close = source.indexOf('}}', open + 2);
      if (close == -1) break;

      final tagContent = source.substring(open + 2, close).trim();

      if (tagContent.startsWith('#') || tagContent.startsWith('^')) {
        depth++;
      } else if (tagContent.startsWith('/')) {
        if (depth > 0) depth--;
      } else if (tagContent == 'else' && depth == 0) {
        final before = source.substring(0, open);
        final after = source.substring(close + 2);
        return MapEntry(before, after);
      }

      index = close + 2;
    }

    return MapEntry(source, null);
  }
}
