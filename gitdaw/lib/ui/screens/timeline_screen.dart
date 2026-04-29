import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import '../../providers/app_mode_provider.dart';
import '../../providers/commits_provider.dart';
import '../../providers/repository_provider.dart';
import '../../providers/file_watcher_provider.dart';
import '../../providers/timeline_provider.dart';
import '../../models/app_mode.dart';
import '../widgets/timeline/timeline_canvas.dart';
import '../widgets/layer_clip/layer_clip_hover_panel.dart';
import '../widgets/pro_mode/git_log_panel.dart';
import '../widgets/pro_mode/manual_commit_panel.dart';
import '../widgets/shared/mode_toggle_button.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) windowManager.addListener(this);
    Future.microtask(() => ref.read(fileWatcherProvider));
  }

  @override
  void dispose() {
    if (!kIsWeb) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);
    final isPro = mode == AppMode.pro;
    final repoAsync = ref.watch(repositoryProvider);
    final isLoading = ref.watch(commitsProvider).isLoading;
    final isDetached = ref.watch(
        timelineProvider.select((s) => s.isDetachedHead));

    final repoName = repoAsync.value?.localPath.split('/').last ?? 'GitDAW';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: Column(
        children: [
          // Custom title bar
          _TitleBar(repoName: repoName),

          // Detached HEAD banner
          if (isDetached) _buildDetachedBanner(ref),

          // Main area
          Expanded(
            child: Row(
              children: [
                // DAW Timeline (main content)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: isLoading && ref.watch(commitsProvider).value == null
                            ? const _LoadingView()
                            : repoAsync.when(
                                data: (repo) => repo == null
                                    ? const _NoRepoView()
                                    : const TimelineCanvas(),
                                loading: () => const _LoadingView(),
                                error: (e, _) =>
                                    _ErrorView(message: e.toString()),
                              ),
                      ),
                      // Hover info panel
                      const LayerClipHoverPanel(),
                    ],
                  ),
                ),

                // Pro mode side panels
                if (isPro)
                  SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        const Expanded(child: GitLogPanel()),
                        const ManualCommitPanel(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetachedBanner(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF5A623).withOpacity(0.12),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 14, color: Color(0xFFF5A623)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '過去のスナップショットを閲覧中です。ファイルは変更されません。',
              style: TextStyle(color: Color(0xFFF5A623), fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(timelineProvider.notifier).setDetachedHead(false),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF5A623)),
            child: const Text('最新に戻る', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends ConsumerWidget {
  final String repoName;
  const _TitleBar({required this.repoName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onPanStart: kIsWeb ? null : (_) => windowManager.startDragging(),
      child: Container(
        height: 44,
        color: const Color(0xFF141420),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Traffic lights area (macOS)
            const SizedBox(width: 70),
            const Spacer(),
            Text(
              repoName,
              style: const TextStyle(
                color: Color(0xFFB0B0C8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: Color(0xFF808098)),
              onPressed: () =>
                  ref.read(commitsProvider.notifier).refresh(),
              tooltip: '更新',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            const SizedBox(width: 6),
            const ModeToggleButton(),
            const SizedBox(width: 6),
            // Settings
            IconButton(
              icon: const Icon(Icons.settings_rounded,
                  size: 16, color: Color(0xFF808098)),
              onPressed: () => context.go('/settings'),
              tooltip: '設定',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF6C8EFF), strokeWidth: 2),
          SizedBox(height: 16),
          Text('読み込み中...', style: TextStyle(color: Color(0xFF808098))),
        ],
      ),
    );
  }
}

class _NoRepoView extends StatelessWidget {
  const _NoRepoView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('リポジトリが選択されていません',
          style: TextStyle(color: Color(0xFF606080))),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('エラー: $message',
          style: const TextStyle(color: Colors.redAccent)),
    );
  }
}
