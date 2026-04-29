class RepositoryModel {
  final String localPath;
  final String? remoteUrl;
  final String currentBranch;
  final bool isInitialized;
  final DateTime? lastSyncTime;

  const RepositoryModel({
    required this.localPath,
    this.remoteUrl,
    required this.currentBranch,
    required this.isInitialized,
    this.lastSyncTime,
  });

  RepositoryModel copyWith({
    String? localPath,
    String? remoteUrl,
    String? currentBranch,
    bool? isInitialized,
    DateTime? lastSyncTime,
  }) {
    return RepositoryModel(
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      currentBranch: currentBranch ?? this.currentBranch,
      isInitialized: isInitialized ?? this.isInitialized,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}
