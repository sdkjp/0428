import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commit_model.dart';
import '../../../models/branch_model.dart';
import '../../../providers/git_service_provider.dart';
import '../../../providers/commits_provider.dart';

class MergeConfirmDialog extends ConsumerStatefulWidget {
  final CommitModel sourceCommit;
  final BranchModel targetBranch;

  const MergeConfirmDialog({
    super.key,
    required this.sourceCommit,
    required this.targetBranch,
  });

  @override
  ConsumerState<MergeConfirmDialog> createState() =>
      _MergeConfirmDialogState();
}

class _MergeConfirmDialogState extends ConsumerState<MergeConfirmDialog> {
  bool _merging = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.merge_type_rounded,
              color: Color(0xFF6C8EFF), size: 22),
          const SizedBox(width: 8),
          const Text('マージの確認'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFFB0B0C8), fontSize: 13),
              children: [
                TextSpan(
                    text: widget.sourceCommit.branchName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const TextSpan(text: ' を '),
                TextSpan(
                    text: widget.targetBranch.displayName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const TextSpan(text: ' にマージします。\nよろしいですか？'),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _merging ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _merging ? null : _doMerge,
          child: _merging
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('マージ'),
        ),
      ],
    );
  }

  Future<void> _doMerge() async {
    setState(() => _merging = true);
    final git = ref.read(gitServiceProvider);
    if (git == null) {
      setState(() {
        _merging = false;
        _error = 'Gitサービスが利用できません';
      });
      return;
    }

    final result = await git.mergeBranch(
      widget.sourceCommit.branchName,
      widget.targetBranch.name,
    );

    if (result.success) {
      await ref.read(commitsProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _merging = false;
        _error = result.hasConflicts
            ? 'コンフリクトが発生しました。手動で解決してください。'
            : (result.errorMessage ?? 'マージに失敗しました');
      });
    }
  }
}
