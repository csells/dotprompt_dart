import 'dart:io';

import 'package:path/path.dart' as path;

import 'partial_resolver.dart';

/// IO implementation of [DotPromptPartialResolver] that looks for partials in
/// the given directories.
class PathPartialResolver implements DotPromptPartialResolver {
  /// Creates a new instance of [PathPartialResolver].
  PathPartialResolver(List<Directory> partialPaths)
    : _partialPaths = partialPaths;

  final List<Directory> _partialPaths;

  @override
  String? resolve(String name) {
    if (_partialPaths.isEmpty) {
      return null;
    }

    for (final partialDir in _partialPaths) {
      // Look for .prompt file
      var partialPath = path.join(partialDir.path, '_$name.prompt');
      if (File(partialPath).existsSync()) {
        final partialContent = File(partialPath).readAsStringSync();
        final parts = partialContent.split('---');
        var template = partialContent;
        if (parts.length >= 2) {
          template =
              parts.length > 2 ? parts.sublist(2).join('---').trim() : '';
        }
        return template;
      }

      // Look for .mustache file
      partialPath = path.join(partialDir.path, '_$name.mustache');
      if (File(partialPath).existsSync()) {
        final partialContent = File(partialPath).readAsStringSync();
        return partialContent;
      }
    }

    return null;
  }
}
