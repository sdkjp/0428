import 'dart:async';
import 'git_service.dart';

// Web stub — File System Access API does not expose change events.
// Auto-commit is triggered manually on web (user action or periodic timer).
class FileWatcherService {
  Stream<void> watch(String _directoryPath) => const Stream.empty();

  Future<void> triggerAutoCommit(GitService gitService) async {
    try {
      await gitService.autoCommitIfChanged();
      gitService.push().catchError((_) {});
    } catch (_) {}
  }

  void dispose() {}
}
