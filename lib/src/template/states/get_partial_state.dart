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
import 'get_path_state.dart';

class GetPartialState extends TemplateState {
  GetPartialState() {
    methods = {'process': process, 'notify': notify};
  }
  String _partialName = '';

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    switch (charCode) {
      case eos:
        return TemplateResult(
          err: TemplateError(
            code: errorUnexpectedEndOfSource,
            text: 'unexpected end of source',
          ),
        );

      case space:
        return null;

      case closeBracket:
        return TemplateResult(state: CloseBracketState());

      default:
        // Start reading the partial name
        if ((charCode >= 65 && charCode <= 90) ||
            (charCode >= 97 && charCode <= 122)) {
          return TemplateResult(
            state: GetPathState(path: String.fromCharCode(charCode)),
          );
        }

        return TemplateResult(
          err: TemplateError(
            code: errorWrongDataSequenceCharacter,
            text: 'Wrong character "${String.fromCharCode(charCode)}" found',
          ),
        );
    }
  }

  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyPathResult:
        // The value might be a Map (named argument) or a String (simple name)
        // For partial names, we only care about strings
        if (msg.value is String) {
          _partialName = msg.value;
        }
        // Named arguments in partials are currently not used but allowed

        return TemplateResult(message: ProcessMessage(charCode: msg.charCode!));
      case notifySecondCloseBracketFound:
        return TemplateResult(pop: true, result: getResult(context));
      default:
        break;
    }

    return null;
  }

  String getResult(TemplateContext context) {
    // Get the partial template source from the partial resolver
    final partialTemplate = context.resolvePartial(_partialName);
    if (partialTemplate != null) {
      // Render the partial template with the current context data
      final machine = TemplateMachine(partialTemplate);
      return machine.run(context);
    }

    return '';
  }
}
