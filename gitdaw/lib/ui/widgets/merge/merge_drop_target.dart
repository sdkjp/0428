import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commit_model.dart';
import '../../../models/branch_model.dart';
import 'merge_confirm_dialog.dart';

class MergeDropTarget extends ConsumerWidget {
  final BranchModel targetBranch;
  final Widget child;

  const MergeDropTarget({
    super.key,
    required this.targetBranch,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<CommitModel>(
      onWillAcceptWithDetails: (details) {
        // Only accept from non-main branches
        return details.data.branchName != targetBranch.name;
      },
      onAcceptWithDetails: (details) {
        showDialog(
          context: context,
          builder: (_) => MergeConfirmDialog(
            sourceCommit: details.data,
            targetBranch: targetBranch,
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: isHovering
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C8EFF).withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: child,
        );
      },
    );
  }
}
