import 'package:flutter/material.dart';

class BranchModel {
  final String name;
  final String displayName;
  final Color trackColor;
  final DateTime? branchPointTime;
  final String? parentBranchName;
  final bool isMain;
  final bool isCollapsed;
  final int trackIndex;

  const BranchModel({
    required this.name,
    required this.displayName,
    required this.trackColor,
    this.branchPointTime,
    this.parentBranchName,
    this.isMain = false,
    this.isCollapsed = false,
    required this.trackIndex,
  });

  BranchModel copyWith({
    String? name,
    String? displayName,
    Color? trackColor,
    DateTime? branchPointTime,
    String? parentBranchName,
    bool? isMain,
    bool? isCollapsed,
    int? trackIndex,
  }) {
    return BranchModel(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      trackColor: trackColor ?? this.trackColor,
      branchPointTime: branchPointTime ?? this.branchPointTime,
      parentBranchName: parentBranchName ?? this.parentBranchName,
      isMain: isMain ?? this.isMain,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      trackIndex: trackIndex ?? this.trackIndex,
    );
  }
}
