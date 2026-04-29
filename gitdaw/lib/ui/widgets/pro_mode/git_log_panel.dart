import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/git_log_provider.dart';

class GitLogPanel extends ConsumerWidget {
  const GitLogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(gitLogProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A12),
        border: Border(left: BorderSide(color: Color(0xFF2A2A40))),
      ),
      child: Column(
        children: [
          _Header(onClear: () => ref.read(gitLogProvider.notifier).clear()),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'コマンドログ',
                      style: TextStyle(color: Color(0xFF404060), fontSize: 12),
                    ),
                  )
                : _LogList(entries: entries),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClear;
  const _Header({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A40))),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal_rounded,
              size: 14, color: Color(0xFF6C8EFF)),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Gitコマンドログ',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all_rounded,
                size: 14, color: Color(0xFF808098)),
            onPressed: onClear,
            tooltip: 'クリア',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _LogList extends StatefulWidget {
  final List<String> entries;
  const _LogList({required this.entries});

  @override
  State<_LogList> createState() => _LogListState();
}

class _LogListState extends State<_LogList> {
  final _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(_LogList old) {
    super.didUpdateWidget(old);
    if (widget.entries.length != old.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: widget.entries.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(
          widget.entries[i],
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            color: Color(0xFF90D090),
          ),
        ),
      ),
    );
  }
}
