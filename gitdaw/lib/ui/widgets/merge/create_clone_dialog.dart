import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commit_model.dart';
import '../../../providers/git_service_provider.dart';
import '../../../providers/commits_provider.dart';

class CreateCloneDialog extends ConsumerStatefulWidget {
  final CommitModel fromCommit;

  const CreateCloneDialog({super.key, required this.fromCommit});

  @override
  ConsumerState<CreateCloneDialog> createState() =>
      _CreateCloneDialogState();
}

class _CreateCloneDialogState extends ConsumerState<CreateCloneDialog> {
  late TextEditingController _ctrl;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: 'クローン2');
    _initName();
  }

  Future<void> _initName() async {
    final git = ref.read(gitServiceProvider);
    if (git == null) return;
    final allAsync = ref.read(commitsProvider);
    final existingNames =
        allAsync.value?.keys.toList() ?? <String>[];
    final name = await git.getNextCloneName(existingNames);
    if (name != null && mounted) _ctrl.text = name;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.call_split_rounded,
              color: Color(0xFF6C8EFF), size: 20),
          const SizedBox(width: 8),
          const Text('クローンを作成'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'コミット ${widget.fromCommit.shortSha} からクローンを作成します',
            style: const TextStyle(color: Color(0xFF808098), fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text('クローン名', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'クローン名を入力',
            ),
            onSubmitted: (_) => _doCreate(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _creating ? null : _doCreate,
          child: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('作成'),
        ),
      ],
    );
  }

  Future<void> _doCreate() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '名前を入力してください');
      return;
    }

    setState(() => _creating = true);
    final git = ref.read(gitServiceProvider);
    if (git == null) {
      setState(() {
        _creating = false;
        _error = 'Gitサービスが利用できません';
      });
      return;
    }

    try {
      await git.createBranch(name, fromSha: widget.fromCommit.sha);
      await ref.read(commitsProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _creating = false;
        _error = 'クローンの作成に失敗しました: $e';
      });
    }
  }
}
