import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commit_model.dart';
import '../../../models/branch_model.dart';
import '../../../core/constants.dart';
import '../layer_clip/layer_clip_widget.dart';
import '../layer_clip/draggable_clip.dart';
import '../merge/merge_drop_target.dart';

class TrackLane extends ConsumerWidget {
  final BranchModel branch;
  final List<CommitModel> commits;
  final DateTime originDate;
  final double pixelsPerDay;
  final double viewportLeft;
  final double viewportRight;

  const TrackLane({
    super.key,
    required this.branch,
    required this.commits,
    required this.originDate,
    required this.pixelsPerDay,
    this.viewportLeft = 0,
    this.viewportRight = double.infinity,
  });

  double _commitX(CommitModel c) {
    final ms = c.timestamp.difference(originDate).inMilliseconds.toDouble();
    return ms / (24 * 3600 * 1000) * pixelsPerDay;
  }

  bool _isInViewport(double x) {
    return x + AppConstants.clipWidth >= viewportLeft &&
        x <= viewportRight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (branch.isCollapsed) {
      return _CollapsedLane(branch: branch);
    }

    // Group commits by day-bucket for stack index calculation
    final bucketMap = <int, List<int>>{}; // dayBucket -> list of commit indices
    for (var i = 0; i < commits.length; i++) {
      final bucket = commits[i].timestamp.difference(originDate).inDays;
      bucketMap.putIfAbsent(bucket, () => []).add(i);
    }

    final stackIndexOf = <int, int>{};
    for (final indices in bucketMap.values) {
      for (var j = 0; j < indices.length; j++) {
        stackIndexOf[indices[j]] = j;
      }
    }

    // Total width of the lane = rightmost clip x + some padding
    final maxX = commits.isEmpty
        ? 400.0
        : (_commitX(commits.first) + AppConstants.clipWidth + 80);

    return Container(
      height: AppConstants.trackHeight,
      decoration: BoxDecoration(
        color: branch.trackColor.withOpacity(0.03),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF2A2A40)),
        ),
      ),
      child: SizedBox(
        width: maxX,
        height: AppConstants.trackHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Track stripe
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      branch.trackColor.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Clips
            ...List.generate(commits.length, (i) {
              final commit = commits[i];
              final x = _commitX(commit);
              final stackIdx = stackIndexOf[i] ?? 0;
              final isLatest = i == 0; // commits are newest-first
              final inViewport = _isInViewport(x);

              // Vertical position: base y + stack offset
              final baseY = (AppConstants.trackHeight -
                          AppConstants.clipHeight) /
                      2 -
                  stackIdx * AppConstants.clipStackOffset;

              Widget clip = LayerClipWidget(
                commit: commit,
                trackColor: branch.trackColor,
                stackIndex: stackIdx,
                isLatest: isLatest,
                isInViewport: inViewport,
              );

              // Wrap latest non-main clip in Draggable for merging
              if (isLatest && !branch.isMain) {
                clip = DraggableClip(
                  commit: commit,
                  trackColor: branch.trackColor,
                  child: clip,
                );
              }

              // Wrap latest main clip in MergeDropTarget
              if (isLatest && branch.isMain) {
                clip = MergeDropTarget(
                  targetBranch: branch,
                  child: clip,
                );
              }

              return Positioned(
                left: x,
                top: baseY,
                child: clip,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CollapsedLane extends StatelessWidget {
  final BranchModel branch;
  const _CollapsedLane({required this.branch});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E14),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E30))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 12, color: branch.trackColor.withOpacity(0.5)),
          const SizedBox(width: 6),
          Text(
            '${branch.displayName}  ✓  マージ済み',
            style: TextStyle(
                color: branch.trackColor.withOpacity(0.45), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
