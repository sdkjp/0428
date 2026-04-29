import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/git_service.dart';
import 'repository_provider.dart';
import 'git_log_provider.dart';

final gitServiceProvider = Provider<GitService?>((ref) {
  final repoAsync = ref.watch(repositoryProvider);
  return repoAsync.whenOrNull(
    data: (repo) {
      if (repo == null || !repo.isInitialized) return null;
      return GitService(
        repoPath: repo.localPath,
        onCommandExecuted: (cmd) {
          ref.read(gitLogProvider.notifier).addEntry(cmd);
        },
      );
    },
  );
});
