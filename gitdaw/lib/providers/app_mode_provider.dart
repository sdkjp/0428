import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';

final appModeProvider =
    NotifierProvider<AppModeNotifier, AppMode>(AppModeNotifier.new);

class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.normal;

  void setMode(AppMode mode) => state = mode;

  void toggle() =>
      state = state == AppMode.normal ? AppMode.pro : AppMode.normal;
}
