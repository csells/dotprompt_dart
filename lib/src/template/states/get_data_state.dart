import 'dart:convert';

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

/// State for processing data variables and helper calls ({{path}} or {{helper
/// args}}).
class GetDataState extends TemplateState {
  /// Creates a get data state with optional HTML escaping and closing brace
  /// count.
  GetDataState({this.escapeValues = true, this.closingBraces = 2}) {
    methods = {'init': init, 'process': process, 'notify': notify};
  }

  /// Whether to HTML-escape the output value.
  final bool escapeValues;

  /// The number of closing braces expected (2 for {{...}}, 3 for {{{...}}}).
  final int closingBraces;

  String _path = '';
  final List<dynamic> _attributes = [];
  bool _isHelper = false;

  static const HtmlEscape _htmlEscape = HtmlEscape(HtmlEscapeMode.element);

  /// Initializes the state with an optional starting path.
  TemplateResult init(InitMessage msg, TemplateContext context) {
    final path = (msg.value as String?) ?? '';

    if (path.isEmpty) {
      return TemplateResult(state: GetPathState());
    }

    return TemplateResult(state: GetPathState(path: path));
  }

  /// Processes characters to collect path or helper arguments.
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
        return TemplateResult(
          state: CloseBracketState(expectedBraces: closingBraces),
        );

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

  /// Handles notifications for path and attribute results.
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

  /// Evaluates the path or helper call and returns the result string.
  String getResult(TemplateContext context) {
    var result = '';

    // Check if this is a helper (either explicitly marked or callable)
    if (context.callable(_path)) {
      if (_attributes.isEmpty) {
        _attributes.add(context.data);
      }
      result = context.call(_path, _attributes);
    } else {
      // Otherwise, get the data value
      final value = context.get(_path);

      if (value != null) {
        result = value.toString();
      }
    }

    if (escapeValues && result.isNotEmpty) {
      return _htmlEscape.convert(result);
    }

    return result;
  }
}
