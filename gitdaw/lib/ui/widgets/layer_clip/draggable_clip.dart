import 'package:flutter/material.dart';
import '../../../models/commit_model.dart';
import '../../../core/constants.dart';
import 'layer_clip_painter.dart';

class DraggableClip extends StatelessWidget {
  final CommitModel commit;
  final Color trackColor;
  final Widget child;

  const DraggableClip({
    super.key,
    required this.commit,
    required this.trackColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<CommitModel>(
      data: commit,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: AppConstants.clipWidth,
            height: AppConstants.clipHeight,
            child: CustomPaint(
              painter: LayerClipPainter(
                baseColor: trackColor,
                isDragging: true,
                isHovered: true,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.merge_type_rounded,
                        size: 16, color: trackColor),
                    const SizedBox(width: 4),
                    Text(
                      'マージ',
                      style: TextStyle(
                        color: trackColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: trackColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'ドラッグ→マージ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
