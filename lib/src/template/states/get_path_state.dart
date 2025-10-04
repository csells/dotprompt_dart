import '../characters_consts.dart';
import '../errors_types.dart';
import '../helper_types.dart';
import '../notify_types.dart';
import '../template_context.dart';
import '../template_error.dart';
import '../template_messages.dart';
import '../template_result.dart';
import '../template_state.dart';
import 'get_attribute_state.dart';

/// State for processing paths (e.g., foo.bar, @index, key=value).
class GetPathState extends TemplateState {
  /// Creates a new path state.
  GetPathState({this.path}) {
    methods = {'process': process, 'notify': notify};
  }

  /// The path being parsed.
  String? path;

  /// For named arguments (key=value).
  String? _key;

  /// The last character processed.
  int? lastChar;

  /// Processes characters to build a path or named argument.
  TemplateResult? process(ProcessMessage msg, TemplateContext context) {
    final charCode = msg.charCode;

    path ??= '';

    if (charCode == eos) {
      return TemplateResult(
        pop: true,
        message: ProcessMessage(charCode: charCode),
      );
    } else if (charCode == dot) {
      // Allow a single '.' as it means "current context" in Mustache
      path = path! + String.fromCharCode(charCode);
    } else if (charCode >= 48 && charCode <= 57) {
      if (path!.isEmpty) {
        return TemplateResult(
          err: TemplateError(
            text: 'Path should not start with number character',
            code: errorPathWrongSpecified,
          ),
        );
      }

      path = path! + String.fromCharCode(charCode);
    } else if ((charCode >= 65 && charCode <= 90) ||
        (charCode >= 97 && charCode <= 122) ||
        charCode == 95 ||
        charCode == 64) {
      // Allow @ for context variables
      path = path! + String.fromCharCode(charCode);
    } else if (charCode == equal) {
      // This is a named argument: key=value
      _key = path;
      path = '';
      return TemplateResult(state: GetAttributeState());
    } else if (charCode == space || charCode == closeBracket) {
      // Allow single '.' as a valid path (means "current context")
      if (lastChar == dot && path != '.') {
        return TemplateResult(
          err: TemplateError(
            text: 'Path should not end with dot character',
            code: errorPathWrongSpecified,
          ),
        );
      }
      return TemplateResult(
        pop: true,
        message: NotifyMessage(
          type: notifyPathResult,
          value: path,
          charCode: charCode,
        ),
      );
    } else {
      return TemplateResult(
        err: TemplateError(
          code: errorNotAValidPathChar,
          text:
              'Character "${String.fromCharCode(charCode)}" is not a valid '
              'in path',
        ),
      );
    }

    lastChar = charCode;

    return null;
  }

  /// Handles attribute notification for named arguments.
  TemplateResult? notify(NotifyMessage msg, TemplateContext context) {
    switch (msg.type) {
      case notifyAttrResult:
        // Got the value for the named argument
        return TemplateResult(
          pop: true,
          message: NotifyMessage(
            charCode: msg.charCode,
            type: notifyPathResult,
            value: NamedArgument(_key!, msg.value),
          ),
        );
    }

    return null;
  }
}
