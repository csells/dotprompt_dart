import '../characters_consts.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'get_block_sequence_type_state.dart';
import 'get_data_state.dart';
import 'get_helper_state.dart';
import 'get_partial_state.dart';
import 'get_sequence_state.dart';
import 'open_bracket_state.dart';

class RootState extends TemplateState {
  RootState() {
    methods = {'process': process, 'notify': notify};
  }
  bool escape = false;

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final res = TemplateResult();
    final charCode = msg.charCode;

    if (charCode == eos) return null;

    if (escape) {
      escape = false;

      res.result = String.fromCharCode(charCode);
    } else {
      switch (charCode) {
        case backSlash:
          escape = true;
        case openBracket:
          res.state = OpenBracketState();
        default:
          res.result = String.fromCharCode(charCode);
      }
    }

    return res;
  }

  TemplateResult notify(NotifyMessage msg, TemplateContext context) {
    final res = TemplateResult();

    switch (msg.type) {
      case notifySecondOpenBracketFound: // done
        res.state = GetSequenceState();
      case notifyIsHelperSequence: // done
        res.message = InitMessage();
        res.state = GetHelperState();
      case notifyIsBlockSequence: // done
        res.message = InitMessage();
        // Check if this is an inverted section (value will be '^')
        final inverted = msg.value == '^';
        res.state = GetBlockSequenceTypeState(inverted: inverted);
      case notifyIsPartialSequence: // done
        res.state = GetPartialState();
      case notifyIsDataSequence: // done
        res.state = GetDataState();
        res.message = InitMessage(value: msg.value);
    }

    return res;
  }
}
