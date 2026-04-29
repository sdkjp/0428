import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/commit_model.dart';
import '../models/branch_model.dart';
import '../models/file_change_model.dart';
import '../core/theme.dart';

class MergeResult {
  final bool success;
  final bool hasConflicts;
  final String? errorMessage;

  const MergeResult({
    required this.success,
    this.hasConflicts = false,
    this.errorMessage,
  });
}

class GitService {
  final String repoPath;
  final void Function(String cmd)? onCommandExecuted;

  const GitService({required this.repoPath, this.onCommandExecuted});

  Future<ProcessResult> _run(List<String> args) async {
    onCommandExecuted?.call('git ${args.join(' ')}');
    return Process.run(
      'git',
      args,
      workingDirectory: repoPath,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  }

  Future<bool> isGitRepo(String path) async {
    try {
      final r = await Process.run('git', ['rev-parse', '--git-dir'],
          workingDirectory: path);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> initRepo(String path) async {
    await Process.run('git', ['init'], workingDirectory: path);
    // Configure identity if not set globally
    await Process.run('git',
        ['config', 'user.email', 'gitdaw@local'], workingDirectory: path);
    await Process.run('git',
        ['config', 'user.name', 'GitDAW'], workingDirectory: path);
    // Create initial empty commit
    await Process.run('git', ['commit', '--allow-empty', '-m', '初期化'],
        workingDirectory: path);
  }

  Future<String> getCurrentBranch() async {
    final r = await _run(['branch', '--show-current']);
    final branch = r.stdout.toString().trim();
    return branch.isEmpty ? 'main' : branch;
  }

  Future<List<CommitModel>> getLog(
      {String? branch, int limit = 300}) async {
    // Custom separator format to safely parse structured output
    const sep = '\x00';
    final fmt =
        '--pretty=format:${sep}SHA${sep}%H${sep}MSG${sep}%s${sep}AUTH${sep}%an${sep}DATE${sep}%aI${sep}END';
    final args = ['log', fmt, '--numstat', '-$limit'];
    if (branch != null) args.add(branch);

    final r = await _run(args);
    if (r.exitCode != 0) return [];
    final currentBranch = branch ?? await getCurrentBranch();
    return _parseLog(r.stdout.toString(), currentBranch);
  }

  List<CommitModel> _parseLog(String output, String branchName) {
    final commits = <CommitModel>[];
    if (output.trim().isEmpty) return commits;

    const sep = '\x00';
    final blocks =
        output.split('${sep}SHA${sep}').where((b) => b.isNotEmpty);

    for (final block in blocks) {
      try {
        final sha = _between(block, '', '${sep}MSG${sep}');
        final msg = _between(block, '${sep}MSG${sep}', '${sep}AUTH${sep}');
        final auth = _between(block, '${sep}AUTH${sep}', '${sep}DATE${sep}');
        final dateStr = _between(block, '${sep}DATE${sep}', '${sep}END');

        if (sha.isEmpty) continue;

        DateTime ts;
        try {
          ts = DateTime.parse(dateStr.trim());
        } catch (_) {
          ts = DateTime.now();
        }

        // numstat lines come after the END marker
        final endIdx = block.indexOf('${sep}END');
        final numstatRaw =
            endIdx >= 0 && endIdx + sep.length + 3 < block.length
                ? block.substring(endIdx + sep.length + 3).trim()
                : '';

        final fileChanges = _parseNumstat(numstatRaw);

        commits.add(CommitModel(
          sha: sha.trim(),
          message: msg.trim(),
          authorName: auth.trim(),
          authorEmail: '',
          timestamp: ts,
          fileChanges: fileChanges,
          branchName: branchName,
        ));
      } catch (_) {
        // Skip malformed blocks
      }
    }
    return commits;
  }

  String _between(String s, String start, String end) {
    final from = start.isEmpty ? 0 : s.indexOf(start);
    if (from < 0) return '';
    final actualFrom = start.isEmpty ? 0 : from + start.length;
    final to = s.indexOf(end, actualFrom);
    if (to < 0) return s.substring(actualFrom);
    return s.substring(actualFrom, to);
  }

  List<FileChangeModel> _parseNumstat(String numstat) {
    final changes = <FileChangeModel>[];
    for (final line in numstat.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final parts = t.split('\t');
      if (parts.length >= 3) {
        final ins = int.tryParse(parts[0]) ?? 0;
        final del = int.tryParse(parts[1]) ?? 0;
        changes.add(FileChangeModel(
          filename: parts[2],
          type: FileChangeType.modified,
          insertions: ins,
          deletions: del,
        ));
      }
    }
    return changes;
  }

  Future<List<BranchModel>> getBranches() async {
    final r = await _run(['branch', '--format=%(refname:short)']);
    if (r.exitCode != 0) return [];

    final names = r.stdout
        .toString()
        .split('\n')
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    final result = <BranchModel>[];
    int idx = 0;
    for (final name in names) {
      final isMain = name == 'main' || name == 'master';
      result.add(BranchModel(
        name: name,
        displayName: isMain ? 'メイン' : name,
        trackColor: AppTheme.trackColorAt(isMain ? 0 : idx + 1),
        isMain: isMain,
        trackIndex: idx,
      ));
      idx++;
    }
    return result;
  }

  Future<bool> hasUncommittedChanges() async {
    final r = await _run(['status', '--porcelain']);
    return r.exitCode == 0 && r.stdout.toString().trim().isNotEmpty;
  }

  Future<void> stageAll() async {
    await _run(['add', '-A']);
  }

  Future<CommitModel> commit(String message) async {
    await _run(['commit', '-m', message]);
    final commits = await getLog(limit: 1);
    if (commits.isNotEmpty) return commits.first;
    return CommitModel(
      sha: 'unknown',
      message: message,
      authorName: 'GitDAW',
      authorEmail: '',
      timestamp: DateTime.now(),
      fileChanges: const [],
      branchName: await getCurrentBranch(),
    );
  }

  Future<CommitModel?> autoCommitIfChanged() async {
    if (!await hasUncommittedChanges()) return null;
    await stageAll();
    final now = DateTime.now();
    final label = DateFormat('yyyy-MM-dd HH:mm').format(now);
    return commit('自動保存 $label');
  }

  Future<void> push({String remote = 'origin', String? branch}) async {
    final br = branch ?? await getCurrentBranch();
    await _run(['push', '--set-upstream', remote, br]);
  }

  Future<void> pull({String remote = 'origin', String? branch}) async {
    final br = branch ?? await getCurrentBranch();
    await _run(['pull', remote, br]);
  }

  Future<void> fetch() async {
    await _run(['fetch', '--all']);
  }

  Future<BranchModel> createBranch(String name, {String? fromSha}) async {
    if (fromSha != null) {
      await _run(['checkout', '-b', name, fromSha]);
    } else {
      await _run(['checkout', '-b', name]);
    }
    final branches = await getBranches();
    return branches.firstWhere(
      (b) => b.name == name,
      orElse: () => BranchModel(
        name: name,
        displayName: name,
        trackColor: AppTheme.trackColorAt(1),
        trackIndex: 1,
      ),
    );
  }

  Future<void> checkoutBranch(String name) async {
    await _run(['checkout', name]);
  }

  Future<MergeResult> mergeBranch(
      String sourceBranch, String targetBranch) async {
    await checkoutBranch(targetBranch);
    final r = await _run(['merge', sourceBranch, '--no-edit']);
    if (r.exitCode == 0) return const MergeResult(success: true);

    final out = '${r.stdout}${r.stderr}';
    final hasConflicts = out.contains('CONFLICT');
    if (hasConflicts) await _run(['merge', '--abort']);
    return MergeResult(
      success: false,
      hasConflicts: hasConflicts,
      errorMessage: r.stderr.toString().trim(),
    );
  }

  Future<void> checkoutCommit(String sha) async {
    await _run(['checkout', sha]);
  }

  Future<void> checkoutLatest(String branch) async {
    await _run(['checkout', branch]);
  }

  Future<String?> getNextCloneName(List<String> existingNames) async {
    for (var i = 2; i <= 20; i++) {
      final candidate = 'クローン$i';
      if (!existingNames.contains(candidate)) return candidate;
    }
    return null;
  }
}
