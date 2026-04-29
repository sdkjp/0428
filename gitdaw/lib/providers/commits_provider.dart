import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/commit_model.dart';
import '../models/branch_model.dart';
import '../core/theme.dart';
import 'git_service_provider.dart';
import 'repository_provider.dart';

// All commits keyed by branch name
final commitsProvider =
    AsyncNotifierProvider<CommitsNotifier, Map<String, List<CommitModel>>>(
  CommitsNotifier.new,
);

// Convenience: commits for a single branch
final branchCommitsProvider =
    Provider.family<List<CommitModel>, String>((ref, branchName) {
  final allAsync = ref.watch(commitsProvider);
  return allAsync.whenOrNull(data: (map) => map[branchName]) ?? [];
});

// All branches derived from the commit map keys
final branchesProvider = Provider<List<BranchModel>>((ref) {
  final allAsync = ref.watch(commitsProvider);
  return allAsync.whenOrNull(data: (map) {
        int idx = 0;
        return map.keys.map((name) {
          final isMain = name == 'main' || name == 'master';
          final model = BranchModel(
            name: name,
            displayName: isMain ? 'メイン' : name,
            trackColor: AppTheme.trackColorAt(isMain ? 0 : idx + 1),
            isMain: isMain,
            trackIndex: idx,
          );
          idx++;
          return model;
        }).toList()
          ..sort((a, b) => a.isMain ? -1 : 1);
      }) ??
      [];
});

class CommitsNotifier
    extends AsyncNotifier<Map<String, List<CommitModel>>> {
  @override
  Future<Map<String, List<CommitModel>>> build() async {
    final git = ref.watch(gitServiceProvider);
    if (git == null) return {};
    // gitServiceProvider already depends on repositoryProvider,
    // so a path change triggers a rebuild here automatically.
    return _fetchAll(git);
  }

  Future<Map<String, List<CommitModel>>> _fetchAll(dynamic git) async {
    final branches = await git.getBranches() as List<BranchModel>;
    final result = <String, List<CommitModel>>{};
    for (final branch in branches) {
      final commits = await git.getLog(branch: branch.name);
      result[branch.name] = commits;
    }
    // Ensure main/master is first
    return Map.fromEntries(
      result.entries.toList()
        ..sort((a, b) {
          final aMain = a.key == 'main' || a.key == 'master';
          final bMain = b.key == 'main' || b.key == 'master';
          return aMain ? -1 : (bMain ? 1 : 0);
        }),
    );
  }

  Future<void> refresh() async {
    final git = ref.read(gitServiceProvider);
    if (git == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAll(git));
  }
}
