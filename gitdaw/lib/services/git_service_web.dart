// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/commit_model.dart';
import '../models/branch_model.dart';
import '../models/file_change_model.dart';
import '../core/theme.dart';

// ---------------------------------------------------------------------------
// JS interop declarations
// ---------------------------------------------------------------------------

@JS('gitdaw.openDirectory')
external JSPromise<JSString?> _jsOpenDirectory();

@JS('gitdaw.isGitRepo')
external JSPromise<JSBoolean> _jsIsGitRepo();

@JS('gitdaw.initRepo')
external JSPromise<JSAny?> _jsInitRepo();

@JS('gitdaw.getCurrentBranch')
external JSPromise<JSString> _jsGetCurrentBranch();

@JS('gitdaw.stageAll')
external JSPromise<JSAny?> _jsStageAll();

@JS('gitdaw.hasUncommittedChanges')
external JSPromise<JSBoolean> _jsHasUncommittedChanges();

@JS('gitdaw.commit')
external JSPromise<JSString> _jsCommit(JSString message);

@JS('gitdaw.checkoutBranch')
external JSPromise<JSAny?> _jsCheckoutBranch(JSString name);

@JS('gitdaw.checkoutCommit')
external JSPromise<JSAny?> _jsCheckoutCommit(JSString sha);

@JS('gitdaw.checkoutLatest')
external JSPromise<JSAny?> _jsCheckoutLatest(JSString branch);

@JS('gitdaw.push')
external JSPromise<JSAny?> _jsPush(JSString? remote, JSString? branch, JSString? token);

@JS('gitdaw.pull')
external JSPromise<JSAny?> _jsPull(JSString? remote, JSString? branch, JSString? token);

@JS('gitdaw.isDirectoryOpen')
external JSBoolean _jsIsDirectoryOpen();

@JS('gitdaw.createBranch')
external JSPromise<JSString> _jsCreateBranch(JSString name, JSString? fromSha);

// JSON-bridge for complex return types
@JS('gitdawJson.getLog')
external JSPromise<JSString> _jsGetLogJson(JSString branch, JSNumber limit);

@JS('gitdawJson.getBranches')
external JSPromise<JSString> _jsGetBranchesJson();

@JS('gitdawJson.mergeBranch')
external JSPromise<JSString> _jsMergeBranchJson(JSString src, JSString tgt);

// ---------------------------------------------------------------------------
// MergeResult mirror
// ---------------------------------------------------------------------------

class MergeResult {
  final bool success;
  final bool hasConflicts;
  final String? errorMessage;
  const MergeResult({required this.success, this.hasConflicts = false, this.errorMessage});
}

// ---------------------------------------------------------------------------
// GitService (web implementation — mirrors git_service_native.dart API)
// ---------------------------------------------------------------------------

class GitService {
  // repoPath is unused on web (path is managed by JS via FileSystemDirectoryHandle)
  // but kept for API compatibility.
  final String repoPath;
  final void Function(String cmd)? onCommandExecuted;

  const GitService({required this.repoPath, this.onCommandExecuted});

  // ── Directory / repo lifecycle ──────────────────────────────────────────

  /// Open a native directory picker. Returns folder name, or null if cancelled.
  static Future<String?> openDirectory() async {
    final result = await _jsOpenDirectory().toDart;
    return result?.toDart;
  }

  static bool isDirectoryOpen() => _jsIsDirectoryOpen().toDart;

  Future<bool> isGitRepo(String _path) async {
    return (await _jsIsGitRepo().toDart).toDart;
  }

  Future<void> initRepo(String _path) async {
    await _jsInitRepo().toDart;
  }

  // ── Read operations ─────────────────────────────────────────────────────

  Future<String> getCurrentBranch() async {
    return (await _jsGetCurrentBranch().toDart).toDart;
  }

  Future<List<BranchModel>> getBranches() async {
    final jsonStr = (await _jsGetBranchesJson().toDart).toDart;
    final list = jsonDecode(jsonStr) as List;
    final result = <BranchModel>[];
    int idx = 0;
    for (final item in list) {
      final name = item['name'] as String;
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

  Future<List<CommitModel>> getLog({String? branch, int limit = 300}) async {
    final jsonStr = (await _jsGetLogJson(
      (branch ?? 'HEAD').toJS,
      limit.toJS,
    ).toDart).toDart;

    final list = jsonDecode(jsonStr) as List;
    final branchName = branch ?? await getCurrentBranch();
    return list.map((e) => _commitFromJson(e as Map<String, dynamic>, branchName)).toList();
  }

  CommitModel _commitFromJson(Map<String, dynamic> e, String branchName) {
    DateTime ts;
    try {
      ts = DateTime.parse(e['isoDate'] as String);
    } catch (_) {
      ts = DateTime.now();
    }
    final files = (e['files'] as List?)?.map((f) {
      final fm = f as Map<String, dynamic>;
      return FileChangeModel(
        filename: fm['path'] as String? ?? '',
        type: FileChangeType.modified,
        insertions: (fm['insertions'] as num?)?.toInt() ?? 0,
        deletions: (fm['deletions'] as num?)?.toInt() ?? 0,
      );
    }).toList() ?? [];

    return CommitModel(
      sha: e['sha'] as String,
      message: e['message'] as String,
      authorName: e['authorName'] as String,
      authorEmail: e['authorEmail'] as String? ?? '',
      timestamp: ts,
      fileChanges: files,
      branchName: branchName,
    );
  }

  // ── Write operations ─────────────────────────────────────────────────────

  Future<bool> hasUncommittedChanges() async {
    return (await _jsHasUncommittedChanges().toDart).toDart;
  }

  Future<void> stageAll() async {
    await _jsStageAll().toDart;
  }

  Future<CommitModel> commit(String message) async {
    final sha = (await _jsCommit(message.toJS).toDart).toDart;
    return CommitModel(
      sha: sha,
      message: message,
      authorName: 'GitDAW User',
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

  Future<BranchModel> createBranch(String name, {String? fromSha}) async {
    await _jsCreateBranch(name.toJS, fromSha?.toJS).toDart;
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
    await _jsCheckoutBranch(name.toJS).toDart;
  }

  Future<void> checkoutCommit(String sha) async {
    await _jsCheckoutCommit(sha.toJS).toDart;
  }

  Future<void> checkoutLatest(String branch) async {
    await _jsCheckoutLatest(branch.toJS).toDart;
  }

  Future<MergeResult> mergeBranch(String sourceBranch, String targetBranch) async {
    final jsonStr = (await _jsMergeBranchJson(
      sourceBranch.toJS,
      targetBranch.toJS,
    ).toDart).toDart;
    final m = jsonDecode(jsonStr) as Map<String, dynamic>;
    return MergeResult(
      success: m['success'] as bool,
      hasConflicts: m['hasConflicts'] as bool? ?? false,
      errorMessage: m['errorMessage'] as String?,
    );
  }

  Future<void> push({String remote = 'origin', String? branch}) async {
    await _jsPush(remote.toJS, branch?.toJS, null).toDart;
  }

  Future<void> pull({String remote = 'origin', String? branch}) async {
    await _jsPull(remote.toJS, branch?.toJS, null).toDart;
  }

  Future<void> fetch() async {
    // fetch is pull without merge — skip for now
  }

  Future<String?> getNextCloneName(List<String> existingNames) async {
    for (var i = 2; i <= 20; i++) {
      final candidate = 'クローン$i';
      if (!existingNames.contains(candidate)) return candidate;
    }
    return null;
  }
}
