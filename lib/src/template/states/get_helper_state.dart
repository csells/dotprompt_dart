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
import 'get_block_name_state.dart';

/// State for processing inline helpers (e.g., {{helper arg1 arg2}}).
class GetHelperState extends TemplateState {
  /// Creates a new helper state.
  GetHelperState() {
    methods = {'init': init, 'process': process, 'notify': notify};
  }
  final List<dynamic> _attributes = [];
  String _helper = '';

  /// Initializes by delegating to block name state.
  TemplateResult init(InitMessage msg, TemplateContext context) =>
      TemplateResult(state: GetBlockNameState());

  /// Processes characters to collect helper attributes.
  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == closeBracket) {
      return TemplateResult(state: CloseBracketState());
    } else if (charCode == space) {
      return null;
    }

    return TemplateResult(
      state: GetAttributeState(),
      message: ProcessMessage(charCode: charCode),
    );
  }

  /// Handles notifications for helper name and attributes.
  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyNameResult:
        _helper = msg.value;

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }

      case notifySecondCloseBracketFound:
        return result(context);

      case notifyAttrResult:
        _attributes.add(msg.value);

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }

      default:
        break;
    }

    return null;
  }

  /// Executes the helper and returns the result.
  TemplateResult result(TemplateContext context) {
    if (!context.callable(_helper)) {
      return TemplateResult(
        pop: true,
        err: TemplateError(
          code: errorHelperUnregistered,
          text: 'Helper "$_helper" is unregistered',
        ),
      );
    }

    final result = TemplateResult();

    try {
      if (_attributes.isEmpty) {
        _attributes.add(context.data);
      }

      result.result = context.call(_helper, _attributes);
      result.pop = true;
    } on Exception catch (e) {
      result.pop = true;
      result.err = TemplateError(
        text: 'Error in helper function $_helper: $e',
        code: errorCallingHelper,
      );
    }

    return result;
  }
}
