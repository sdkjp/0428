import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commit_model.dart';
import '../../../providers/commits_provider.dart';
import '../../../providers/timeline_provider.dart';
import '../../../providers/git_service_provider.dart';
import '../../../core/constants.dart';
import 'timeline_ruler.dart';
import 'track_lane.dart';
import 'track_header.dart';
import 'scrub_cursor.dart';

class TimelineCanvas extends ConsumerStatefulWidget {
  const TimelineCanvas({super.key});

  @override
  ConsumerState<TimelineCanvas> createState() => _TimelineCanvasState();
}

class _TimelineCanvasState extends ConsumerState<TimelineCanvas> {
  final _hScrollCtrl = ScrollController();
  bool _isDraggingScrub = false;

  @override
  void dispose() {
    _hScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(commitsProvider);
    final branches = ref.watch(branchesProvider);
    final state = ref.watch(timelineProvider);

    // Compute origin date = earliest commit minus 1 day
    final originDate = allAsync.whenOrNull(data: (map) {
      DateTime? earliest;
      for (final commits in map.values) {
        for (final c in commits) {
          if (earliest == null || c.timestamp.isBefore(earliest)) {
            earliest = c.timestamp;
          }
        }
      }
      return earliest != null
          ? DateTime(earliest.year, earliest.month,
              earliest.day - 1)
          : DateTime.now().subtract(const Duration(days: 1));
    }) ??
        DateTime.now().subtract(const Duration(days: 1));

    // Total timeline width
    final totalWidth = _computeTotalWidth(allAsync.value ?? {}, originDate, state.pixelsPerDay);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final trackAreaHeight = branches.fold<double>(
            0,
            (sum, b) => sum +
                (b.isCollapsed
                    ? 32
                    : AppConstants.trackHeight));

        return Column(
          children: [
            // Ruler + track headers row
            Row(
              children: [
                // Corner
                Container(
                  width: AppConstants.trackHeaderWidth,
                  height: AppConstants.timelineRulerHeight,
                  color: const Color(0xFF141420),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Text(
                    'トラック',
                    style: TextStyle(
                        color: Color(0xFF606080),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                // Scrollable ruler
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: TimelineRuler(
                      originDate: originDate,
                      pixelsPerDay: state.pixelsPerDay,
                      width: totalWidth,
                    ),
                  ),
                ),
              ],
            ),

            // Tracks area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed left headers
                  SizedBox(
                    width: AppConstants.trackHeaderWidth,
                    child: Column(
                      children: branches
                          .map((b) => TrackHeader(
                              branch: b,
                              isCollapsed: b.isCollapsed))
                          .toList(),
                    ),
                  ),
                  // Scrollable track lanes
                  Expanded(
                    child: Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          // Ctrl+scroll = zoom, plain scroll = horizontal pan
                          if (event.kind == PointerDeviceKind.mouse &&
                              event.scrollDelta.dy != 0) {
                            final delta = -event.scrollDelta.dy;
                            final zoom = state.pixelsPerDay *
                                (1 + delta * 0.001);
                            ref
                                .read(timelineProvider.notifier)
                                .setZoom(zoom);
                          }
                        }
                      },
                      child: GestureDetector(
                        onTapDown: (details) =>
                            _onTapTimeline(details, originDate, state),
                        onHorizontalDragStart: (details) {
                          _isDraggingScrub = true;
                          _updateScrub(details.localPosition.dx +
                              _hScrollCtrl.offset, originDate, state, scrubbing: true);
                        },
                        onHorizontalDragUpdate: (details) {
                          if (_isDraggingScrub) {
                            _updateScrub(details.localPosition.dx +
                                _hScrollCtrl.offset, originDate, state, scrubbing: true);
                          }
                        },
                        onHorizontalDragEnd: (_) async {
                          _isDraggingScrub = false;
                          final sha = ref
                              .read(timelineProvider)
                              .scrubCommitSha;
                          if (sha != null) {
                            await _checkoutCommit(sha);
                          }
                          ref
                              .read(timelineProvider.notifier)
                              .setScrub(null, scrubbing: false);
                        },
                        child: SingleChildScrollView(
                          controller: _hScrollCtrl,
                          scrollDirection: Axis.horizontal,
                          child: Stack(
                            children: [
                              SizedBox(
                                width: totalWidth,
                                height: trackAreaHeight,
                                child: Column(
                                  children: branches.map((branch) {
                                    final commits =
                                        ref.watch(branchCommitsProvider(branch.name));
                                    return TrackLane(
                                      branch: branch,
                                      commits: commits,
                                      originDate: originDate,
                                      pixelsPerDay: state.pixelsPerDay,
                                      viewportLeft: _hScrollCtrl.hasClients
                                          ? _hScrollCtrl.offset
                                          : 0,
                                      viewportRight: _hScrollCtrl.hasClients
                                          ? _hScrollCtrl.offset + canvasWidth
                                          : canvasWidth,
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Scrub cursor overlay
                              ScrubCursor(
                                originDate: originDate,
                                pixelsPerDay: state.pixelsPerDay,
                                timelineHeight: trackAreaHeight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  double _computeTotalWidth(
      Map<String, List<CommitModel>> allCommits,
      DateTime originDate,
      double pixelsPerDay) {
    DateTime? latest;
    for (final commits in allCommits.values) {
      for (final c in commits) {
        if (latest == null || c.timestamp.isAfter(latest)) {
          latest = c.timestamp;
        }
      }
    }
    if (latest == null) return 800;
    final days = latest.difference(originDate).inDays + 3;
    return (days * pixelsPerDay).clamp(800.0, double.infinity);
  }

  void _updateScrub(
      double absoluteX, DateTime originDate, TimelineViewState state,
      {bool scrubbing = false}) {
    final msPerPixel =
        (24 * 3600 * 1000) / state.pixelsPerDay;
    final ms = absoluteX * msPerPixel;
    final targetTime =
        originDate.add(Duration(milliseconds: ms.round()));

    // Find nearest commit
    final allCommits = ref.read(commitsProvider).value ?? {};
    CommitModel? nearest;
    int minDiff = 999999999;
    for (final commits in allCommits.values) {
      for (final c in commits) {
        final diff = (c.timestamp.difference(targetTime).inMinutes).abs();
        if (diff < minDiff) {
          minDiff = diff;
          nearest = c;
        }
      }
    }

    if (nearest != null) {
      ref
          .read(timelineProvider.notifier)
          .setScrub(nearest.sha, scrubbing: scrubbing);
    }
  }

  void _onTapTimeline(
      TapDownDetails details, DateTime originDate, TimelineViewState state) {
    // Single click: set scrub cursor position
    _updateScrub(
        details.localPosition.dx + _hScrollCtrl.offset, originDate, state);
  }

  Future<void> _checkoutCommit(String sha) async {
    final git = ref.read(gitServiceProvider);
    if (git == null) return;
    try {
      await git.checkoutCommit(sha);
      ref.read(timelineProvider.notifier).setDetachedHead(true);
    } catch (_) {}
  }
}
