import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/git_service_provider.dart';
import '../../../providers/commits_provider.dart';

class ManualCommitPanel extends ConsumerStatefulWidget {
  const ManualCommitPanel({super.key});

  @override
  ConsumerState<ManualCommitPanel> createState() =>
      _ManualCommitPanelState();
}

class _ManualCommitPanelState extends ConsumerState<ManualCommitPanel> {
  final _ctrl = TextEditingController();
  bool _committing = false;
  String? _status;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF12121E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A40))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('手動コミット',
              style: TextStyle(color: Color(0xFF6C8EFF), fontSize: 11)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: 'コミットメッセージ',
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _committing ? null : _doCommit,
                  icon: _committing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 14),
                  label: const Text('コミット', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _committing ? null : _doStageAll,
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label:
                      const Text('ステージ', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFF3A3A54)),
                    foregroundColor: const Color(0xFFB0B0C8),
                  ),
                ),
              ),
            ],
          ),
          if (_status != null) ...[
            const SizedBox(height: 6),
            Text(_status!,
                style:
                    const TextStyle(color: Color(0xFF90D090), fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Future<void> _doStageAll() async {
    final git = ref.read(gitServiceProvider);
    if (git == null) return;
    setState(() => _committing = true);
    try {
      await git.stageAll();
      setState(() {
        _committing = false;
        _status = 'すべての変更をステージしました';
      });
    } catch (e) {
      setState(() {
        _committing = false;
        _status = 'エラー: $e';
      });
    }
  }

  Future<void> _doCommit() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    final git = ref.read(gitServiceProvider);
    if (git == null) return;
    setState(() => _committing = true);
    try {
      await git.stageAll();
      await git.commit(msg);
      await ref.read(commitsProvider.notifier).refresh();
      _ctrl.clear();
      setState(() {
        _committing = false;
        _status = 'コミットしました';
      });
    } catch (e) {
      setState(() {
        _committing = false;
        _status = 'エラー: $e';
      });
    }
  }
}
