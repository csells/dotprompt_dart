import 'characters_consts.dart';
import 'errors_types.dart';
import 'states/root_state.dart';
import 'template_context.dart';
import 'template_messages.dart';
import 'template_result.dart';
import 'template_state.dart';

/// State machine that processes template source and generates rendered output.
///
/// The machine uses a stack-based architecture with different states handling
/// different template constructs (variables, helpers, blocks, etc.).
class TemplateMachine {
  /// Creates a template machine with the given template source.
  TemplateMachine(String? tpl) {
    _template = tpl;
  }
  final List<TemplateState> _stack = [];
  final StringBuffer _resBuffer = StringBuffer();

  String? _template;

  int _line = 0; // template lining support
  int _symbol = 0;

  String _currentLine = '';
  bool _standaloneCandidate = false;
  bool _pendingStandalone = false;
  final StringBuffer _postTagBuffer = StringBuffer();

  /// Runs the state machine with the given context and returns rendered output.
  ///
  /// Processes the template source character by character, managing state
  /// transitions and accumulating output text.
  String run(TemplateContext context) {
    _stack.clear();
    _stack.add(RootState());
    _resBuffer.clear();

    if (_template != null && _template!.isNotEmpty) {
      final lines = _template!.split('\n');

      for (var l = 0; l < lines.length; l++) {
        _line = l + 1;
        final line = lines[l];

        for (var i = 0; i < line.length; i++) {
          //print('Current state is: ${_stack.last}');
          _symbol = i;
          final charCode = line.codeUnitAt(i);

          //print("char: ${line[i]}");

          context.symbol = _symbol;
          context.line = _line;

          _process(ProcessMessage(charCode: charCode), context);
        }

        if (l < lines.length - 1) {
          _process(ProcessMessage(charCode: enter), context);
        }
      }

      _process(ProcessMessage(charCode: eos), context);

      if (_stack.last is! RootState) {
        throw Exception(
          'Something go wrong: please check your template for issues.',
        );
      }
    }

    return _resBuffer.toString();
  }

  /// Processing machine message
  void _process(TemplateMessage msg, TemplateContext context) {
    final state = _stack.last;

    if (msg is ProcessMessage &&
        state is RootState &&
        msg.charCode == openBracket) {
      _standaloneCandidate = _currentLine.trim().isEmpty;
      _pendingStandalone = false;
      _postTagBuffer.clear();
    }

    if (state.canAcceptMessage(msg)) {
      final res = state.processMessage(msg, context);

      if (res != null) {
        _processResult(res, context);
      }
    }
  }

  void _appendString(String text) {
    for (var i = 0; i < text.length; i++) {
      final char = text[i];

      if (_pendingStandalone) {
        if (char == '\n') {
          _postTagBuffer.clear();
          _pendingStandalone = false;
          _currentLine = '';
          continue;
        } else if (char == ' ' || char == '\t') {
          _postTagBuffer.write(char);
          continue;
        } else if (char == '\r') {
          _postTagBuffer.write(char);
          continue;
        } else {
          if (_postTagBuffer.isNotEmpty) {
            final buffered = _postTagBuffer.toString();
            _resBuffer.write(buffered);
            for (var j = 0; j < buffered.length; j++) {
              final bufferedChar = buffered[j];
              if (bufferedChar == '\n') {
                _currentLine = '';
              } else if (bufferedChar != '\r') {
                _currentLine += bufferedChar;
              }
            }
            _postTagBuffer.clear();
          }
          _pendingStandalone = false;
        }
      }

      _resBuffer.write(char);
      if (char == '\n') {
        _currentLine = '';
      } else if (char != '\r') {
        _currentLine += char;
      }
    }
  }

  /// Processing message result
  void _processResult(TemplateResult r, TemplateContext context) {
    if (r.result != null) {
      _appendString(r.result!);
    }

    if (r.pop ?? false) {
      // Store state before popping if needed for debugging
      // final poppedState = _stack.isNotEmpty ? _stack.last : null;
      pop();
      final returningToRoot = _stack.isNotEmpty && _stack.last is RootState;

      if (returningToRoot) {
        if (_standaloneCandidate) {
          if (r.result == null || r.result!.isEmpty) {
            _pendingStandalone = true;
            _postTagBuffer.clear();
          } else {
            _pendingStandalone = false;
            _postTagBuffer.clear();
          }
        }
        _standaloneCandidate = false;
      }
    }

    if (r.state != null) {
      _stack.add(r.state!);
    }

    if (r.message != null) {
      _process(r.message!, context);
    }

    if (r.err != null) {
      if (context.opt('ignoreUnregisteredHelperErrors') == true &&
          r.err!.code == errorHelperUnregistered) {
        // Warning suppressed - helper unregistered but ignored
      } else {
        final e = 'Error (${r.err!.code}) on $_line:$_symbol ${r.err!.text}';
        throw Exception(e);
      }
    }
  }

  /// Pops top state from stack
  void pop() {
    _stack.removeLast();
  }
}
