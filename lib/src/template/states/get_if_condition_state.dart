import '../characters_consts.dart';
import '../errors_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'get_attribute_state.dart';
import 'get_condition_state.dart';

class GetIfConditionState extends TemplateState {
  GetIfConditionState() {
    methods = {'process': process, 'notify': notify};
  }
  dynamic leftPart;
  dynamic rightPart;
  String? condition;

  int _state = 0;

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == eos) {
      return TemplateResult(
        err: TemplateError(
          code: errorUnexpectedEndOfSource,
          text: 'unexpected end of source',
        ),
      );
    } else if (charCode == closeBracket) {
      // If we have leftPart (even if null), that's valid - it's a simple truthy check
      if (_state >= 1) {
        return TemplateResult(
          pop: true,
          message: NotifyMessage(
            value: checkCondition(),
            type: notifyConditionResult,
            charCode: charCode,
          ),
        );
      }
      return TemplateResult(
        err: TemplateError(
          text: 'If block condition malformed',
          code: errorIfBlockMalformed,
        ),
      );
    } else if (charCode == space) {
      return null;
    } else {
      switch (_state) {
        case 0:
          return TemplateResult(
            state: GetAttributeState(),
            message: ProcessMessage(charCode: charCode),
          );

        case 1:
          return TemplateResult(
            state: GetConditionState(),
            message: ProcessMessage(charCode: charCode),
          );

        case 2:
          return TemplateResult(
            state: GetAttributeState(),
            message: ProcessMessage(charCode: charCode),
          );

        default:
          return null;
      }
    }
  }

  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyAttrResult:
        if (_state == 0) {
          leftPart = msg.value;
          _state++;

          // Reprocess the charCode to continue parsing
          if (msg.charCode != null) {
            return TemplateResult(
              message: ProcessMessage(charCode: msg.charCode!),
            );
          }
        } else if (_state == 2) {
          rightPart = msg.value;

          return TemplateResult(
            pop: true,
            message: NotifyMessage(
              value: checkCondition(),
              type: notifyConditionResult,
              charCode: msg.charCode,
            ),
          );
        } else {
          return TemplateResult(
            err: TemplateError(
              text: 'If block condition malformed',
              code: errorIfBlockMalformed,
            ),
          );
        }

      case notifyConditionResult:
        condition = msg.value;
        _state++;

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }

      default:
        return TemplateResult(
          err: TemplateError(
            code: errorUnsupportedNotify,
            text:
                'State "$runtimeType" does not support notifies of type ${msg.type}',
          ),
        );
    }

    return null;
  }

  bool checkCondition() {
    // If no condition operator, just check truthiness of leftPart
    if (condition == null) {
      return _isTruthy(leftPart);
    }

    // Otherwise, perform comparison
    switch (condition) {
      case '<':
        return leftPart < rightPart;
      case '<=':
        return leftPart <= rightPart;
      case '>':
        return leftPart > rightPart;
      case '>=':
        return leftPart >= rightPart;
      case '==':
        return leftPart == rightPart;
      case '!=':
        return leftPart != rightPart;
      default:
        return false;
    }
  }

  /// Checks if a value is truthy according to Handlebars semantics
  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    if (value is num) return value != 0;
    return true;
  }
}
