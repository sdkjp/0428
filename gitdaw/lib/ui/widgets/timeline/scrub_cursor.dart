import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/timeline_provider.dart';
import '../../../providers/commits_provider.dart';
import '../../../providers/git_service_provider.dart';
import '../../../models/commit_model.dart';

class ScrubCursor extends ConsumerWidget {
  final DateTime originDate;
  final double pixelsPerDay;
  final double timelineHeight;

  const ScrubCursor({
    super.key,
    required this.originDate,
    required this.pixelsPerDay,
    required this.timelineHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineProvider);
    if (!state.isScrubbing && state.scrubCommitSha == null) {
      return const SizedBox.shrink();
    }

    // Find the commit
    final allAsync = ref.watch(commitsProvider);
    CommitModel? commit;
    allAsync.whenOrNull(data: (map) {
      for (final commits in map.values) {
        for (final c in commits) {
          if (c.sha == state.scrubCommitSha) {
            commit = c;
            return;
          }
        }
      }
    });

    if (commit == null) return const SizedBox.shrink();

    final dayOffset = commit!.timestamp
        .difference(originDate)
        .inMilliseconds
        .toDouble();
    final x = dayOffset / (24 * 3600 * 1000) * pixelsPerDay;

    return Positioned(
      left: x - 1,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Column(
          children: [
            _ScrubLabel(commit: commit!, pixelsPerDay: pixelsPerDay),
            Container(
              width: 2,
              height: timelineHeight,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrubLabel extends StatelessWidget {
  final CommitModel commit;
  final double pixelsPerDay;
  const _ScrubLabel({required this.commit, required this.pixelsPerDay});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('M/d HH:mm');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        fmt.format(commit.timestamp.toLocal()),
        style: const TextStyle(
            color: Color(0xFF0E0E14),
            fontSize: 10,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// Overlay banner shown when in detached HEAD (time-travel) mode
class DetachedHeadBanner extends ConsumerWidget {
  final CommitModel commit;
  const DetachedHeadBanner({super.key, required this.commit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF5A623).withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 16, color: Color(0xFFF5A623)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '閲覧モード: ${commit.timestamp.toLocal()} のスナップショット',
              style: const TextStyle(
                  color: Color(0xFFF5A623), fontSize: 12),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final git = ref.read(gitServiceProvider);
              if (git == null) return;
              await git.checkoutLatest(commit.branchName);
              ref.read(timelineProvider.notifier).setDetachedHead(false);
            },
            icon: const Icon(Icons.undo_rounded,
                size: 14, color: Color(0xFFF5A623)),
            label: const Text('最新に戻る',
                style: TextStyle(
                    color: Color(0xFFF5A623), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
