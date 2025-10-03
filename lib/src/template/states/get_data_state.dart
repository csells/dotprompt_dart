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
import 'get_path_state.dart';

class GetDataState extends TemplateState {
  GetDataState() {
    methods = {'init': init, 'process': process, 'notify': notify};
  }
  String _path = '';
  final List<dynamic> _attributes = [];
  bool _isHelper = false;

  TemplateResult init(InitMessage msg, TemplateContext context) {
    final path = msg.value;

    return TemplateResult(state: GetPathState(path: path));
  }

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
        // If we have a path and it's a helper, start collecting attributes
        if (_path.isNotEmpty && context.callable(_path)) {
          _isHelper = true;
          return null;
        }
        // Otherwise space in data sequence is an error
        if (!_isHelper) {
          return null;
        }
        return null;

      case closeBracket:
        return TemplateResult(state: CloseBracketState());

      default:
        // If this is a helper, allow collecting attributes
        if (_isHelper) {
          return TemplateResult(
            state: GetAttributeState(),
            message: ProcessMessage(charCode: charCode),
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
        _path = msg.value;

        return TemplateResult(message: ProcessMessage(charCode: msg.charCode!));
      case notifyAttrResult:
        _attributes.add(msg.value);

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }
      case notifySecondCloseBracketFound:
        return TemplateResult(pop: true, result: getResult(context));
      default:
        break;
    }

    return null;
  }

  String getResult(TemplateContext context) {
    var result = '';

    // If this is a helper, call it
    if (_isHelper && context.callable(_path)) {
      if (_attributes.isEmpty) {
        _attributes.add(context.data);
      }
      result = context.call(_path, _attributes, null);
    } else {
      // Otherwise, get the data value
      final value = context.get(_path);

      if (value != null) {
        result = value.toString();
      }
    }

    return result;
  }
}
