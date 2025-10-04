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
import 'get_block_end_state.dart';

/// State for processing custom block helpers (e.g., {{#customHelper}}).
class GetBlockHelperState extends TemplateState {
  /// Creates a new block helper state.
  GetBlockHelperState({
    required this.helper,
    required this.symbol,
    required this.line,
  }) {
    methods = {'process': process, 'notify': notify};
  }

  /// The name of the block helper.
  final String helper;
  final List<dynamic> _attributes = [];

  /// The column position where the block started.
  final int symbol;

  /// The line number where the block started.
  final int line;

  String _body = '';
  String? _inverseBody;

  /// Processes characters to collect helper attributes.
  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    if (charCode == eos) {
      return TemplateResult(
        err: TemplateError(
          code: errorUnterminatedBlock,
          text: 'Unterminated block helper "$helper" at $line:$symbol',
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

  /// Handles notifications for attributes and block end.
  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifySecondCloseBracketFound:
        return TemplateResult(state: GetBlockEndState(blockName: helper));

      case notifyAttrResult:
        _attributes.add(msg.value);

        if (msg.charCode != null) {
          return TemplateResult(
            message: ProcessMessage(charCode: msg.charCode!),
          );
        }

      case notifyBlockEndResult:
        _parseBody(msg.value);

        return result(context);

      default:
        break;
    }

    return null;
  }

  void _parseBody(String raw) {
    final split = _splitElse(raw);
    _body = split.key;
    _inverseBody = split.value;
  }

  MapEntry<String, String?> _splitElse(String source) {
    var depth = 0;
    var index = 0;

    while (index < source.length) {
      final open = source.indexOf('{{', index);
      if (open == -1) break;
      final close = source.indexOf('}}', open + 2);
      if (close == -1) break;

      final tagContent = source.substring(open + 2, close).trim();

      if (tagContent.startsWith('#') || tagContent.startsWith('^')) {
        depth++;
      } else if (tagContent.startsWith('/')) {
        if (depth > 0) depth--;
      } else if (tagContent == 'else' && depth == 0) {
        final before = source.substring(0, open);
        final after = source.substring(close + 2);
        return MapEntry(before, after);
      }

      index = close + 2;
    }

    return MapEntry(source, null);
  }

  /// Executes the block helper and returns the result.
  TemplateResult result(TemplateContext context) {
    if (!context.callable(helper)) {
      return TemplateResult(
        err: TemplateError(
          code: errorHelperUnregistered,
          text: 'Helper "$helper" is unregistered',
        ),
      );
    }

    final result = TemplateResult();

    try {
      if (_attributes.isEmpty) {
        _attributes.add(context.data);
      }
      final blockRenderer = _createRenderer(_body, context);
      final inverseRenderer =
          _inverseBody != null ? _createRenderer(_inverseBody!, context) : null;

      result.result = context.call(
        helper,
        _attributes,
        block: blockRenderer,
        inverse: inverseRenderer,
      );
      result.pop = true;
    } on Exception catch (e) {
      result.err = TemplateError(
        text: 'Helper "$helper" error: $e',
        code: errorCallingHelper,
      );
    }

    return result;
  }

  BlockRenderer _createRenderer(String body, TemplateContext context) {
    final template = body;
    return ([dynamic renderContext, Map<String, dynamic>? locals]) {
      final childContext = context.child(
        renderContext ?? context.data,
        locals: locals,
      );
      final machine = TemplateMachine(template);
      return machine.run(childContext);
    };
  }
}
