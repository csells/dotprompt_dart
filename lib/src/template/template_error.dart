/// Represents a template parsing or rendering error.
///
/// Contains an error code (see error constants in errors_types.dart)
/// and a descriptive error message.
class TemplateError {
  /// Creates a template error with the given [code] and [text].
  TemplateError({required this.code, required this.text});

  /// The numeric error code (see errors_types.dart for constants).
  final int code;

  /// A descriptive error message.
  final String text;
}
