import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repository_model.dart';
import '../services/git_service.dart';

final selectedRepoPathProvider =
    NotifierProvider<SelectedRepoPathNotifier, String?>(
        SelectedRepoPathNotifier.new);

class SelectedRepoPathNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setPath(String? path) => state = path;
}

final repositoryProvider =
    AsyncNotifierProvider<RepositoryNotifier, RepositoryModel?>(
  RepositoryNotifier.new,
);

class RepositoryNotifier extends AsyncNotifier<RepositoryModel?> {
  @override
  Future<RepositoryModel?> build() async {
    final path = ref.watch(selectedRepoPathProvider);
    if (path == null) return null;
    return _loadRepo(path);
  }

  Future<RepositoryModel?> _loadRepo(String path) async {
    final git = GitService(repoPath: path);
    final isGit = await git.isGitRepo(path);

    String currentBranch = 'main';
    if (isGit) {
      try {
        currentBranch = await git.getCurrentBranch();
      } catch (_) {}
    }

    return RepositoryModel(
      localPath: path,
      remoteUrl: null,
      currentBranch: currentBranch,
      isInitialized: isGit,
    );
  }

  Future<void> initializeRepo() async {
    final path = ref.read(selectedRepoPathProvider);
    if (path == null) return;
    state = const AsyncValue.loading();
    try {
      final git = GitService(repoPath: path);
      await git.initRepo(path);
      state = AsyncValue.data(await _loadRepo(path));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() => ref.invalidateSelf();
}
