import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commit_model.dart';
import '../../../providers/timeline_provider.dart';
import '../../../core/constants.dart';
import 'layer_clip_painter.dart';

class LayerClipWidget extends ConsumerStatefulWidget {
  final CommitModel commit;
  final Color trackColor;
  final int stackIndex;
  final bool isLatest;
  final bool isInViewport;

  const LayerClipWidget({
    super.key,
    required this.commit,
    required this.trackColor,
    this.stackIndex = 0,
    this.isLatest = false,
    this.isInViewport = true,
  });

  @override
  ConsumerState<LayerClipWidget> createState() => _LayerClipWidgetState();
}

class _LayerClipWidgetState extends ConsumerState<LayerClipWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoveredSha =
        ref.watch(timelineProvider.select((s) => s.hoveredCommitSha));
    final isHovered = _isHovered || hoveredSha == widget.commit.sha;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        ref.read(timelineProvider.notifier).setHovered(widget.commit.sha);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        ref.read(timelineProvider.notifier).setHovered(null);
      },
      child: SizedBox(
        width: AppConstants.clipWidth,
        height: AppConstants.clipHeight,
        child: widget.isInViewport
            ? _buildWithBlur(isHovered)
            : _buildWithoutBlur(isHovered),
      ),
    );
  }

  Widget _buildWithBlur(bool isHovered) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.clipRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: _buildContent(isHovered),
      ),
    );
  }

  Widget _buildWithoutBlur(bool isHovered) {
    return _buildContent(isHovered);
  }

  Widget _buildContent(bool isHovered) {
    return CustomPaint(
      painter: LayerClipPainter(
        baseColor: widget.trackColor,
        stackIndex: widget.stackIndex,
        isHovered: isHovered,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.layers_rounded,
                  size: 11,
                  color: widget.trackColor.withOpacity(0.85),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.commit.shortSha,
                    style: TextStyle(
                      fontSize: 9,
                      color: widget.trackColor.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isLatest)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: widget.trackColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '最新',
                      style: TextStyle(
                          fontSize: 8,
                          color: widget.trackColor,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                widget.commit.displayLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.commit.authorName,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.45),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
