import 'dart:async';
import 'package:watcher/watcher.dart';
import 'git_service.dart';

class FileWatcherService {
  StreamSubscription<WatchEvent>? _subscription;
  Timer? _debounceTimer;
  bool _disposed = false;

  static const _ignored = ['.git', '.DS_Store', 'node_modules', '__pycache__'];

  // Returns a debounced stream: each item means "something changed"
  Stream<void> watch(String directoryPath) {
    final controller = StreamController<void>.broadcast();

    final watcher = DirectoryWatcher(directoryPath);
    _subscription = watcher.events.listen((event) {
      if (_disposed) return;
      if (_shouldIgnore(event.path)) return;

      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        if (!controller.isClosed) controller.add(null);
      });
    });

    return controller.stream;
  }

  bool _shouldIgnore(String path) {
    return _ignored.any((pattern) => path.contains(pattern));
  }

  // Trigger the auto-commit pipeline
  Future<void> triggerAutoCommit(GitService gitService) async {
    try {
      await gitService.autoCommitIfChanged();
      // Best-effort push; failure is non-blocking
      gitService.push().catchError((_) {});
    } catch (_) {
      // Swallow errors from auto-commit to avoid disrupting the user
    }
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _subscription?.cancel();
  }
}
