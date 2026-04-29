import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repository_model.dart';

// The selected local folder path — null means no repo opened
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
    final gitCheck = await Process.run('git', ['rev-parse', '--git-dir'],
        workingDirectory: path);
    final isGit = gitCheck.exitCode == 0;

    String currentBranch = 'main';
    String? remoteUrl;

    if (isGit) {
      final branchResult = await Process.run(
          'git', ['branch', '--show-current'],
          workingDirectory: path);
      final br = branchResult.stdout.toString().trim();
      if (br.isNotEmpty) currentBranch = br;

      final remoteResult = await Process.run(
          'git', ['remote', 'get-url', 'origin'],
          workingDirectory: path);
      if (remoteResult.exitCode == 0) {
        remoteUrl = remoteResult.stdout.toString().trim();
      }
    }

    return RepositoryModel(
      localPath: path,
      remoteUrl: remoteUrl,
      currentBranch: currentBranch,
      isInitialized: isGit,
    );
  }

  Future<void> initializeRepo() async {
    final path = ref.read(selectedRepoPathProvider);
    if (path == null) return;
    state = const AsyncValue.loading();
    try {
      await Process.run('git', ['init'], workingDirectory: path);
      await Process.run('git', ['config', 'user.email', 'gitdaw@local'],
          workingDirectory: path);
      await Process.run('git', ['config', 'user.name', 'GitDAW'],
          workingDirectory: path);
      await Process.run('git', ['commit', '--allow-empty', '-m', '初期化'],
          workingDirectory: path);
      state = AsyncValue.data(await _loadRepo(path));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
