import '../characters_consts.dart';
import '../errors_types.dart';
import '../helper_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_machine.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'close_bracket_state.dart';
import 'get_attribute_state.dart';
import 'get_path_state.dart';

/// State for processing partials ({{>partialName}}).
class GetPartialState extends TemplateState {
  /// Creates a new partial state.
  GetPartialState() {
    methods = {'process': process, 'notify': notify};
  }
  String _partialName = '';
  final List<dynamic> _attributes = [];
  bool _readingName = true;

  /// Processes characters to collect partial name and arguments.
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
        if (_readingName) {
          if ((charCode >= 65 && charCode <= 90) ||
              (charCode >= 97 && charCode <= 122) ||
              charCode == dot ||
              charCode == underscore) {
            return TemplateResult(
              state: GetPathState(path: String.fromCharCode(charCode)),
            );
          }
        } else {
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

  /// Handles notifications for partial name and attributes.
  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyPathResult:
        if (_readingName) {
          _partialName = msg.value;
          _readingName = false;
        } else {
          if (msg.value is NamedArgument) {
            _attributes.add(msg.value);
          } else if (msg.value is String) {
            _attributes.add(context.get(msg.value));
          } else {
            _attributes.add(msg.value);
          }
        }

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }
      case notifySecondCloseBracketFound:
        return TemplateResult(pop: true, result: getResult(context));
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

  /// Resolves and renders the partial template.
  String getResult(TemplateContext context) {
    // Get the partial template source from the partial resolver
    final partialTemplate = context.resolvePartial(_partialName);
    if (partialTemplate != null) {
      final partialContextValue = _buildPartialContextValue(context);
      final partialContext = context.child(partialContextValue);
      final machine = TemplateMachine(partialTemplate);
      return machine.run(partialContext);
    }

    return '';
  }

  dynamic _buildPartialContextValue(TemplateContext context) {
    if (_attributes.isEmpty) {
      return context.data;
    }

    final positional = <dynamic>[];
    final named = <String, dynamic>{};

    for (final attr in _attributes) {
      if (attr is NamedArgument) {
        named[attr.key] = attr.value;
        continue;
      }

      positional.add(attr);
    }

    final dynamic base =
        positional.isNotEmpty ? positional.first : context.data;

    if (named.isEmpty) return base;

    if (base is Map<String, dynamic>) {
      return {...base, ...named};
    }

    if (base is Map) {
      return {
        ...base.map((key, value) => MapEntry(key.toString(), value)),
        ...named,
      };
    }

    if (base == null) {
      return named;
    }

    return {...named, 'this': base};
  }
}
