import 'package:flutter_riverpod/flutter_riverpod.dart';

final gitLogProvider =
    NotifierProvider<GitLogNotifier, List<String>>(GitLogNotifier.new);

class GitLogNotifier extends Notifier<List<String>> {
  static const _maxEntries = 500;

  @override
  List<String> build() => [];

  void addEntry(String command) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final entry = '[$ts] $command';
    final next = [...state, entry];
    state = next.length > _maxEntries
        ? next.sublist(next.length - _maxEntries)
        : next;
  }

  void clear() => state = [];
}
