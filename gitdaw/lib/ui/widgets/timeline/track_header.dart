import 'package:flutter/material.dart';
import '../../../models/branch_model.dart';
import '../../../core/constants.dart';

class TrackHeader extends StatelessWidget {
  final BranchModel branch;
  final bool isCollapsed;

  const TrackHeader({
    super.key,
    required this.branch,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: AppConstants.trackHeaderWidth,
      height: isCollapsed ? 32 : AppConstants.trackHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        border: Border(
          right: BorderSide(
              color: branch.trackColor.withOpacity(0.3), width: 2),
          bottom: const BorderSide(color: Color(0xFF2A2A40)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: isCollapsed
          ? _CollapsedHeader(branch: branch)
          : _ExpandedHeader(branch: branch),
    );
  }
}

class _ExpandedHeader extends StatelessWidget {
  final BranchModel branch;
  const _ExpandedHeader({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: branch.trackColor,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                branch.displayName,
                style: TextStyle(
                  color: branch.trackColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!branch.isMain && branch.branchPointTime != null) ...[
          const SizedBox(height: 4),
          Text(
            branch.name,
            style: const TextStyle(
                color: Color(0xFF606080), fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _CollapsedHeader extends StatelessWidget {
  final BranchModel branch;
  const _CollapsedHeader({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: branch.trackColor.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${branch.displayName} (マージ済み)',
          style: const TextStyle(
            color: Color(0xFF606080),
            fontSize: 10,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
