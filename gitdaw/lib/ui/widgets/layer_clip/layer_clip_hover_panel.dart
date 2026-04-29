import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/commit_model.dart';
import '../../../providers/timeline_provider.dart';
import '../../../providers/commits_provider.dart';
import '../../../providers/git_service_provider.dart';
import '../../widgets/merge/create_clone_dialog.dart';

class LayerClipHoverPanel extends ConsumerWidget {
  const LayerClipHoverPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoveredSha =
        ref.watch(timelineProvider.select((s) => s.hoveredCommitSha));
    if (hoveredSha == null) return const SizedBox.shrink();

    // Find the hovered commit across all branches
    final allCommitsAsync = ref.watch(commitsProvider);
    final commit = allCommitsAsync.whenOrNull(data: (map) {
      for (final commits in map.values) {
        for (final c in commits) {
          if (c.sha == hoveredSha) return c;
        }
      }
      return null;
    });

    if (commit == null) return const SizedBox.shrink();

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: _HoverPanelContent(commit: commit),
    );
  }
}

class _HoverPanelContent extends ConsumerWidget {
  final CommitModel commit;
  const _HoverPanelContent({required this.commit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('yyyy-MM-dd  HH:mm');
    final isDetached =
        ref.watch(timelineProvider.select((s) => s.isDetachedHead));

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        border: const Border(
            top: BorderSide(color: Color(0xFF2A2A44), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Left: date/time
          SizedBox(
            width: 160,
            child: Text(
              dateFmt.format(commit.timestamp.toLocal()),
              style: const TextStyle(
                  color: Color(0xFF808098), fontSize: 12),
            ),
          ),
          // Center: display label
          Expanded(
            child: Text(
              commit.displayLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Right: author + size
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(commit.authorName,
                  style: const TextStyle(
                      color: Color(0xFFB0B0C8), fontSize: 11)),
              Text(commit.changeSizeLabel,
                  style: const TextStyle(
                      color: Color(0xFF808098), fontSize: 10)),
            ],
          ),
          const SizedBox(width: 16),
          // Action buttons
          if (!isDetached) ...[
            _PanelButton(
              label: 'ここでクローンを作成',
              icon: Icons.call_split_rounded,
              onTap: () => _showCloneDialog(context, ref, commit),
            ),
            const SizedBox(width: 8),
          ],
          if (isDetached)
            _PanelButton(
              label: '最新に戻る',
              icon: Icons.undo_rounded,
              color: const Color(0xFFF5A623),
              onTap: () => _returnToLatest(ref),
            ),
        ],
      ),
    );
  }

  void _showCloneDialog(
      BuildContext context, WidgetRef ref, CommitModel commit) {
    showDialog(
      context: context,
      builder: (ctx) => CreateCloneDialog(fromCommit: commit),
    );
  }

  Future<void> _returnToLatest(WidgetRef ref) async {
    final git = ref.read(gitServiceProvider);
    if (git == null) return;
    // Return to the branch's latest state
    final branch = commit.branchName;
    await git.checkoutLatest(branch);
    ref.read(timelineProvider.notifier).setDetachedHead(false);
  }
}

class _PanelButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PanelButton({
    required this.label,
    required this.icon,
    this.color = const Color(0xFF6C8EFF),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
