import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';

class TimelineViewState {
  final double scrollOffsetMs;
  final double pixelsPerDay;
  final String? hoveredCommitSha;
  final String? scrubCommitSha;
  final bool isScrubbing;
  final bool isDetachedHead;

  const TimelineViewState({
    this.scrollOffsetMs = 0,
    this.pixelsPerDay = AppConstants.initialPixelsPerDay,
    this.hoveredCommitSha,
    this.scrubCommitSha,
    this.isScrubbing = false,
    this.isDetachedHead = false,
  });

  TimelineViewState copyWith({
    double? scrollOffsetMs,
    double? pixelsPerDay,
    String? hoveredCommitSha,
    bool clearHovered = false,
    String? scrubCommitSha,
    bool clearScrub = false,
    bool? isScrubbing,
    bool? isDetachedHead,
  }) {
    return TimelineViewState(
      scrollOffsetMs: scrollOffsetMs ?? this.scrollOffsetMs,
      pixelsPerDay: pixelsPerDay ?? this.pixelsPerDay,
      hoveredCommitSha:
          clearHovered ? null : (hoveredCommitSha ?? this.hoveredCommitSha),
      scrubCommitSha:
          clearScrub ? null : (scrubCommitSha ?? this.scrubCommitSha),
      isScrubbing: isScrubbing ?? this.isScrubbing,
      isDetachedHead: isDetachedHead ?? this.isDetachedHead,
    );
  }
}

final timelineProvider =
    NotifierProvider<TimelineNotifier, TimelineViewState>(TimelineNotifier.new);

class TimelineNotifier extends Notifier<TimelineViewState> {
  @override
  TimelineViewState build() => const TimelineViewState();

  void setHovered(String? sha) =>
      state = state.copyWith(hoveredCommitSha: sha, clearHovered: sha == null);

  void setScrub(String? sha, {bool scrubbing = false}) => state = state.copyWith(
        scrubCommitSha: sha,
        clearScrub: sha == null,
        isScrubbing: scrubbing,
      );

  void setZoom(double pixelsPerDay) {
    final clamped = pixelsPerDay.clamp(
        AppConstants.minPixelsPerDay, AppConstants.maxPixelsPerDay);
    state = state.copyWith(pixelsPerDay: clamped);
  }

  void setDetachedHead(bool value) =>
      state = state.copyWith(isDetachedHead: value);

  void reset() => state = const TimelineViewState();
}
