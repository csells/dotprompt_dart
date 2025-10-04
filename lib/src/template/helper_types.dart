import 'template_context.dart';

/// Function signature for rendering a block of template content.
typedef BlockRenderer =
    String Function([dynamic context, Map<String, dynamic>? locals]);

/// Represents a named argument passed to a helper.
///
/// Named arguments use the form `key=value` in templates:
/// `{{helper arg1 name="value"}}`.
class NamedArgument {
  /// Creates a named argument with the given [key] and [value].
  const NamedArgument(this.key, this.value);

  /// The argument name.
  final String key;

  /// The argument value.
  final dynamic value;
}

/// Provides metadata about a helper invocation.
///
/// This class encapsulates all information needed by a helper function:
/// context, arguments, and optional block renderers for block helpers.
class HelperInvocation {
  /// Creates a helper invocation with the given parameters.
  HelperInvocation({
    required this.context,
    required this.positionalArgs,
    required this.namedArgs,
    this.block,
    this.inverse,
  });

  /// The current template context when the helper is invoked.
  final TemplateContext context;

  /// Positional arguments supplied to the helper.
  final List<dynamic> positionalArgs;

  /// Named arguments supplied to the helper.
  final Map<String, dynamic> namedArgs;

  /// Renderer for the main block when invoked as a block helper.
  final BlockRenderer? block;

  /// Renderer for the inverse block (e.g. `{{else}}`).
  final BlockRenderer? inverse;

  /// Returns the first positional argument or `null` when none provided.
  dynamic get firstPositional =>
      positionalArgs.isNotEmpty ? positionalArgs.first : null;

  /// Provides read-only access to a named argument.
  dynamic named(String key) => namedArgs[key];
}

/// Signature all helpers must implement.
typedef TemplateHelper = String Function(HelperInvocation invocation);
