/// error object, that can be returned by message in TemplateResult
class TemplateError {
  TemplateError({required this.code, required this.text});
  final int code;
  final String text;
}
