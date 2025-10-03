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
import 'get_section_state.dart';
import 'get_with_block_state.dart';

class GetBlockSequenceTypeState extends TemplateState {
  GetBlockSequenceTypeState({this.inverted = false}) {
    methods = {'init': init, 'process': process, 'notify': notify};
  }

  final bool inverted;

  TemplateResult init(InitMessage msg, TemplateContext context) =>
      TemplateResult(state: GetBlockNameState());

  TemplateResult process(ProcessMessage msg, TemplateContext context) =>
      TemplateResult(
        pop: true,
        message: ProcessMessage(charCode: msg.charCode),
      );

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
            // 'unless' is like an inverted 'if' - implement it here
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
            // Must be a registered helper
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
        text:
            'State "$runtimeType" does not support notifies of type ${msg.type}',
      ),
    );
  }
}
