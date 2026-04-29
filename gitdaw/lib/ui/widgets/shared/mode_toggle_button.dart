import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_mode_provider.dart';
import '../../../models/app_mode.dart';

class ModeToggleButton extends ConsumerWidget {
  const ModeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final isPro = mode == AppMode.pro;

    return Tooltip(
      message: isPro ? '通常モードに切り替え' : 'プロモードに切り替え',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ref.read(appModeProvider.notifier).toggle(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isPro
                ? const Color(0xFF9B6CFF).withOpacity(0.2)
                : const Color(0xFF2A2A40),
            border: Border.all(
              color: isPro
                  ? const Color(0xFF9B6CFF).withOpacity(0.6)
                  : const Color(0xFF3A3A54),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPro ? Icons.terminal_rounded : Icons.tune_rounded,
                size: 14,
                color: isPro
                    ? const Color(0xFF9B6CFF)
                    : const Color(0xFF808098),
              ),
              const SizedBox(width: 5),
              Text(
                isPro ? 'PRO' : '通常',
                style: TextStyle(
                  color: isPro
                      ? const Color(0xFF9B6CFF)
                      : const Color(0xFF808098),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
