import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../providers/repository_provider.dart';
import '../widgets/shared/glass_container.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GlassFolderHero(),
                const SizedBox(height: 48),
                Text(
                  'GitDAW',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 42,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ファイルの変更を音楽のように管理する',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF808098),
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 56),
                _OpenFolderButton(onPressed: () => _pickFolder(context, ref)),
                const SizedBox(height: 16),
                Text(
                  'フォルダを選択してGitDAWを開始',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6C8EFF).withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF9B6CFF).withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFolder(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'フォルダを選択してください',
    );
    if (result == null) return;

    ref.read(selectedRepoPathProvider.notifier).setPath(result);

    // Check if it's a git repo; if not, offer to initialize
    final isGit = await Process.run('git', ['rev-parse', '--git-dir'],
            workingDirectory: result)
        .then((r) => r.exitCode == 0);

    if (!isGit && context.mounted) {
      final shouldInit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gitが見つかりません'),
          content: const Text(
              'このフォルダはまだGitで管理されていません。\n今すぐ初期化しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('初期化する'),
            ),
          ],
        ),
      );
      if (shouldInit == true) {
        await ref.read(repositoryProvider.notifier).initializeRepo();
      }
    }

    if (context.mounted) {
      context.go('/timeline');
    }
  }
}

class _OpenFolderButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _OpenFolderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        width: 240,
        height: 54,
        borderRadius: 27,
        color: const Color(0xFF6C8EFF),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'フォルダを開く',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassFolderHero extends StatelessWidget {
  const _GlassFolderHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF4A90D9).withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Glass panel stack (3D illusion)
        Transform.translate(
          offset: const Offset(8, 8),
          child: _glassFolderTile(const Color(0xFF3A3A60), 0.3),
        ),
        Transform.translate(
          offset: const Offset(4, 4),
          child: _glassFolderTile(const Color(0xFF4A4A80), 0.45),
        ),
        _glassFolderTile(const Color(0xFF6C8EFF), 0.65),
        const Icon(Icons.folder_rounded, size: 56, color: Colors.white),
      ],
    );
  }

  Widget _glassFolderTile(Color color, double opacity) {
    return Container(
      width: 100,
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(opacity * 0.3),
        border: Border.all(color: color.withOpacity(opacity), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
