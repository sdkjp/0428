enum FileChangeType { added, modified, deleted, renamed, unknown }

class FileChangeModel {
  final String filename;
  final FileChangeType type;
  final int insertions;
  final int deletions;

  const FileChangeModel({
    required this.filename,
    this.type = FileChangeType.modified,
    this.insertions = 0,
    this.deletions = 0,
  });

  String get displayName {
    final parts = filename.replaceAll('\\', '/').split('/');
    return parts.last;
  }

  String get changeSizeLabel => '+$insertions / -$deletions';
}
