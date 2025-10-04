import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'get_block_helper_state.dart';
import 'get_block_name_state.dart';
import 'get_each_block_state.dart';
import 'get_if_block_state.dart';
import 'get_with_block_state.dart';

/// State for determining block type (if, unless, each, with, or custom helper).
class GetBlockSequenceTypeState extends TemplateState {
  /// Creates a new block sequence type state.
  GetBlockSequenceTypeState({this.inverted = false}) {
    methods = {'init': init, 'process': process, 'notify': notify};
  }

  /// Whether this is an inverted block (^).
  final bool inverted;

  /// Initializes by delegating to block name state.
  TemplateResult init(InitMessage msg, TemplateContext context) =>
      TemplateResult(state: GetBlockNameState());

  /// Processes characters by delegating to parent state.
  TemplateResult process(ProcessMessage msg, TemplateContext context) =>
      TemplateResult(
        pop: true,
        message: ProcessMessage(charCode: msg.charCode),
      );

  /// Handles block name notification and routes to appropriate block state.
  TemplateResult notify(NotifyMessage msg, TemplateContext context) {
    if (msg.type == notifyNameResult) {
      final String blockName = msg.value;

      if (blockName.isEmpty) {
        return TemplateResult(
          err: TemplateError(
            code: errorBlockNameWrongSpecified,
            text: 'Block name not specified',
          ),
        );
      } else {
        final res = TemplateResult(
          pop: true,
          message: ProcessMessage(charCode: msg.charCode!),
        );

        // Only spec-defined blocks are supported: if, unless, each, with
        // Everything else must be a registered helper
        switch (blockName) {
          case 'if':
            res.state = GetIfBlockState(
              line: context.line,
              symbol: context.symbol,
            );
          case 'unless':
            res.state = GetIfBlockState(
              line: context.line,
              symbol: context.symbol,
              inverted: true,
              blockName: 'unless',
            );
          case 'with':
            res.state = GetWithBlockState(
              line: context.line,
              symbol: context.symbol,
            );
          case 'each':
            res.state = GetEachBlockState(
              line: context.line,
              symbol: context.symbol,
            );
          default:
            res.state = GetBlockHelperState(
              helper: blockName,
              line: context.line,
              symbol: context.symbol,
            );
        }

        return res;
      }
    }

    return TemplateResult(
      err: TemplateError(
        code: errorUnsupportedNotify,
        text: 'State "GetBlockSequenceTypeState" does not support '
            'notifies of type ${msg.type}',
      ),
    );
  }
}
