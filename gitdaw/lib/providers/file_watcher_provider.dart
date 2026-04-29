import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_watcher_service.dart';
import 'repository_provider.dart';
import 'git_service_provider.dart';
import 'commits_provider.dart';
import 'app_mode_provider.dart';
import '../models/app_mode.dart';

final fileWatcherProvider =
    AsyncNotifierProvider<FileWatcherNotifier, void>(FileWatcherNotifier.new);

class FileWatcherNotifier extends AsyncNotifier<void> {
  final _watcher = FileWatcherService();
  StreamSubscription<void>? _sub;

  @override
  Future<void> build() async {
    final repoAsync = ref.watch(repositoryProvider);
    final repo = repoAsync.value;
    final mode = ref.watch(appModeProvider);

    _sub?.cancel();
    _watcher.dispose();

    if (repo == null || !repo.isInitialized || mode == AppMode.pro) return;

    final stream = _watcher.watch(repo.localPath);
    _sub = stream.listen((_) async {
      final git = ref.read(gitServiceProvider);
      if (git == null) return;
      await _watcher.triggerAutoCommit(git);
      ref.read(commitsProvider.notifier).refresh();
    });

    ref.onDispose(() {
      _sub?.cancel();
      _watcher.dispose();
    });
  }
}
