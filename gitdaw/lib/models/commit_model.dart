import 'file_change_model.dart';

class CommitModel {
  final String sha;
  final String message;
  final String authorName;
  final String authorEmail;
  final DateTime timestamp;
  final List<FileChangeModel> fileChanges;
  final String branchName;

  const CommitModel({
    required this.sha,
    required this.message,
    required this.authorName,
    required this.authorEmail,
    required this.timestamp,
    required this.fileChanges,
    required this.branchName,
  });

  String get shortSha => sha.length >= 7 ? sha.substring(0, 7) : sha;

  String get displayLabel {
    if (fileChanges.isNotEmpty) {
      return '【${fileChanges.first.displayName}】の修正';
    }
    return message.isNotEmpty ? message : shortSha;
  }

  int get totalInsertions =>
      fileChanges.fold(0, (sum, f) => sum + f.insertions);
  int get totalDeletions => fileChanges.fold(0, (sum, f) => sum + f.deletions);

  String get changeSizeLabel => '+$totalInsertions / -$totalDeletions';

  CommitModel copyWith({String? branchName}) {
    return CommitModel(
      sha: sha,
      message: message,
      authorName: authorName,
      authorEmail: authorEmail,
      timestamp: timestamp,
      fileChanges: fileChanges,
      branchName: branchName ?? this.branchName,
    );
  }
}
