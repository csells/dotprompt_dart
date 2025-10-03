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

class GetBlockSequenceTypeState extends TemplateState {
  GetBlockSequenceTypeState() {
    methods = {'init': init, 'process': process, 'notify': notify};
  }

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

        switch (blockName) {
          case 'if':
            res.state = GetIfBlockState(
              line: context.line,
              symbol: context.symbol,
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
        text:
            'State "$runtimeType" does not support notifies of type ${msg.type}',
      ),
    );
  }
}
