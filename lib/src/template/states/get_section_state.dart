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
import 'get_attribute_state.dart';
import 'get_block_end_state.dart';

/// Handles generic Mustache/Handlebars sections {{#name}}...{{/name}}
/// and inverted sections {{^name}}...{{/name}}
class GetSectionState extends TemplateState {
  GetSectionState({
    required this.sectionName,
    required this.symbol,
    required this.line,
    this.inverted = false,
  }) {
    methods = {'process': process, 'notify': notify};
  }

  final String sectionName;
  final int symbol;
  final int line;
  final bool inverted;
  final List<dynamic> _attributes = [];

  String _body = '';

  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == eos) {
      return TemplateResult(
        err: TemplateError(
          code: errorUnterminatedBlock,
          text: 'Unterminated section "$sectionName" at $line:$symbol',
        ),
      );
    } else if (charCode == closeBracket) {
      return TemplateResult(state: CloseBracketState());
    } else if (charCode == space) {
      return null;
    }

    return TemplateResult(
      state: GetAttributeState(),
      message: ProcessMessage(charCode: charCode),
    );
  }

  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifySecondCloseBracketFound:
        return TemplateResult(state: GetBlockEndState(blockName: sectionName));

      case notifyAttrResult:
        _attributes.add(msg.value);

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }

      case notifyBlockEndResult:
        _body = msg.value;

        return result(context);

      default:
        break;
    }

    return null;
  }

  TemplateResult result(TemplateContext context) {
    final result = TemplateResult();
    result.pop = true;

    // Get the value from context
    final value = context.get(sectionName);

    // Determine if we should render based on value and inverted flag
    final shouldRender = inverted ? !_isTruthy(value) : _isTruthy(value);

    if (!shouldRender) {
      result.result = '';
      return result;
    }

    // Handle different value types
    if (value is List) {
      // Iterate over list items
      final buffer = StringBuffer();
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        // Create a new context with the item as the current context
        final itemContext = TemplateContext(
          item is Map ? item : {'.': item, 'this': item},
          context.helpers as Map<String, Function(List<dynamic>, Function?)>?,
          context.opt('options'),
          null,
          context.resolvePartial,
        );

        final machine = TemplateMachine(_body);
        buffer.write(machine.run(itemContext));
      }
      result.result = buffer.toString();
    } else if (value is Map) {
      // Use the map as context
      final newContext = TemplateContext(
        value,
        context.helpers as Map<String, Function(List<dynamic>, Function?)>?,
        context.opt('options'),
        null,
        context.resolvePartial,
      );

      final machine = TemplateMachine(_body);
      result.result = machine.run(newContext);
    } else {
      // For simple values (boolean, string, etc.), just render the body
      final machine = TemplateMachine(_body);
      result.result = machine.run(context);
    }

    return result;
  }

  /// Checks if a value is truthy according to Mustache/Handlebars semantics
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
