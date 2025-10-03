// ignore: unused_import
import 'partial_resolver_web.dart'
    if (dart.library.io) 'path_partial_resolver.dart';

/// A class for resolving partials.
abstract class DotPromptPartialResolver {
  /// The resolver function that returns the partial template source.
  String? resolve(String name);
}
