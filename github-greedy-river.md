# GitDAW — Git GUI Client with DAW Metaphor

## Context

Office workers and non-programmers need to use GitHub for version-controlled document management, but standard Git CLI tools and even most Git GUIs assume programming knowledge. This app reframes Git as a **Digital Audio Workstation (DAW)** — a metaphor familiar from music production software like Logic Pro or Cubase — where:

- **Branches** = Instrument tracks (horizontal lanes)
- **Commits** = Glass "layer clips" placed on a time-axis
- **Merging** = Drag a clip from a clone track onto the Main track
- **Time travel** = Scrub the cursor left/right on the timeline

The result: version control that "feels like shopping" — intuitive, visual, no terminal required.

---

## Tech Stack

- **Framework**: Flutter (Dart) — desktop-first, targets macOS/Windows/Linux, also iOS/Android-capable
- **Git operations**: `dart:io` `Process.run()` shell calls (transparent, auditable, reliable)
- **File watching**: `watcher` Dart package with 2-second debounce
- **State**: Riverpod 3 with code generation (`riverpod_annotation`)
- **Navigation**: `go_router`
- **Window control**: `window_manager`
- **Credentials**: `flutter_secure_storage`
- **Folder picker**: `file_picker`

---

## Project Structure

```
/Users/__s__d__k__/Desktop/Project/0428/gitdaw/
├── pubspec.yaml
├── macos/Runner/DebugProfile.entitlements   ← add git + network permissions
├── macos/Runner/Release.entitlements        ← same
├── assets/
│   ├── fonts/NotoSansJP-Regular.ttf
│   └── icons/                               ← folder SVG assets
└── lib/
    ├── main.dart
    ├── app.dart                             ← ProviderScope + MaterialApp
    ├── core/
    │   ├── constants.dart                   ← track heights, palette, timing
    │   ├── theme.dart                       ← dark glass theme
    │   └── router.dart                      ← go_router: welcome → timeline
    ├── models/
    │   ├── repository_model.dart
    │   ├── branch_model.dart                ← name, color, branchPointTime, isCollapsed
    │   ├── commit_model.dart                ← sha, message, timestamp, fileChanges, author
    │   ├── file_change_model.dart
    │   └── app_mode.dart                   ← enum AppMode { normal, pro }
    ├── services/
    │   ├── git_service.dart                 ← ALL git shell commands (critical)
    │   ├── file_watcher_service.dart        ← watcher + debounce + auto-commit pipeline
    │   ├── github_service.dart              ← GitHub REST API (remote URL, auth)
    │   └── credential_service.dart          ← flutter_secure_storage wrapper
    ├── providers/
    │   ├── repository_provider.dart         ← AsyncNotifier<RepositoryModel>
    │   ├── commits_provider.dart            ← AsyncNotifier<List<CommitModel>> (central)
    │   ├── branch_provider.dart             ← StreamNotifier<List<BranchModel>>
    │   ├── file_watcher_provider.dart       ← StreamNotifier, triggers auto-commit
    │   ├── timeline_provider.dart           ← scrollOffset, pixelsPerDay, hoveredSha
    │   ├── app_mode_provider.dart           ← StateProvider<AppMode>
    │   └── git_log_provider.dart            ← Notifier<List<String>> for Pro mode
    └── ui/
        ├── screens/
        │   ├── welcome_screen.dart          ← folder picker + glass folder icon
        │   ├── timeline_screen.dart         ← main DAW canvas
        │   └── settings_screen.dart
        └── widgets/
            ├── timeline/
            │   ├── timeline_canvas.dart     ← InteractiveViewer + track layout (critical)
            │   ├── track_lane.dart          ← one branch row; clips as positioned Stack
            │   ├── track_header.dart        ← left sidebar, branch name + color
            │   ├── timeline_ruler.dart      ← date ticks, zoom-aware
            │   └── scrub_cursor.dart        ← draggable vertical line → checkout commit
            ├── layer_clip/
            │   ├── layer_clip_widget.dart   ← MouseRegion + BackdropFilter blur
            │   ├── layer_clip_painter.dart  ← CustomPainter: 3D glass shading (critical)
            │   ├── layer_clip_hover_panel.dart ← slides in below: date/filename/author/size
            │   └── draggable_clip.dart      ← Draggable wrapper for merge
            ├── merge/
            │   ├── merge_drop_target.dart   ← DragTarget on Main's latest clip
            │   └── merge_confirm_dialog.dart
            ├── pro_mode/
            │   ├── git_log_panel.dart
            │   └── manual_commit_panel.dart
            └── shared/
                ├── glass_container.dart     ← BackdropFilter reusable widget
                ├── mode_toggle_button.dart
                └── folder_picker_button.dart
```

---

## Critical Files & Key Designs

### `git_service.dart` — Public API

```dart
class GitService {
  final String repoPath;
  final void Function(String cmd)? onCommandExecuted; // Pro mode log

  Future<bool>              isGitRepo(String path);
  Future<void>              initRepo(String path);
  Future<List<CommitModel>> getLog({String? branch, int limit = 200});
  Future<List<BranchModel>> getBranches();
  Future<String>            getCurrentBranch();
  Future<void>              stageAll();
  Future<CommitModel>       commit(String message);
  Future<void>              push({String remote = 'origin', String? branch});
  Future<void>              pull();
  Future<void>              fetch();
  Future<BranchModel>       createBranch(String name, {String? fromSha});
  Future<void>              checkoutBranch(String name);
  Future<MergeResult>       mergeBranch(String source, String target);
  Future<void>              checkoutCommit(String sha);   // detached HEAD
  Future<void>              checkoutLatest(String branch);
}
```

`git log` uses a custom separator format to parse commits reliably:
```
git log --pretty=format:"^^SHA^^%H^^MSG^^%s^^AUTH^^%an^^DATE^^%aI^^" --numstat
```

### `layer_clip_painter.dart` — 3D Glass Effect

`CustomPainter` draws per clip:
1. Semi-transparent rounded rect fill (base color at ~30% opacity)
2. White gradient on top edge (simulates light hitting glass)
3. Vertical gradient on left edge
4. Inner shadow at bottom-right for depth
5. 1px white border at 30% opacity
6. A darker shifted copy behind it (`stackIndex × 3px`) to simulate physical stacking

Performance: `BackdropFilter` blur is only mounted on the ~5 clips visible in viewport (culled by comparing `clip.x` to `scrollOffset ± screenWidth`).

### `file_watcher_service.dart` — Auto-Commit Pipeline (Normal Mode)

```
FileWatchEvent → 2s debounce → stageAll() → commit("自動保存 yyyy-MM-dd HH:mm")
               → push() [fire-and-forget] → invalidate commitsProvider → UI updates
```

Ignored patterns: `.git/`, `.DS_Store`, `*.tmp`, `node_modules/`

### Timeline Layout Math

```
x = (commit.timestamp.ms - timelineOriginMs) / msPerPixel
msPerPixel = (24 * 3600 * 1000) / pixelsPerDay   // pixelsPerDay starts at 200
```

Clips with the same day bucket stack vertically 4px per `stackIndex` to simulate 3D layers (DAW clip stacking).

---

## UI Flow

```
WelcomeScreen
  → pick folder (file_picker)
  → detect/init git repo
  → navigate to TimelineScreen

TimelineScreen (DAW layout):
  Left: TrackHeaderColumn (branch names + colors)
  Center: InteractiveViewer
    ├─ TimelineRuler (date ticks)
    ├─ TrackLane "Main" — glass clips as positioned Stack
    │   └─ MergeDropTarget (on latest clip)
    └─ TrackLane "クローン2" — clips + DraggableClip (latest)
  Bottom: AnimatedSlide LayerClipHoverPanel (appears on hover)
  Overlay: ScrubCursor (vertical line, draggable)
  Right drawer (Pro mode): GitLogPanel + ManualCommitPanel

Hover panel content:
  "2024-03-15  14:32"   |  【report.xlsx】の修正  |  田中 太郎 / +42 -7

Clone creation:
  Hover layer → "ここでクローンを作成" button →
  Dialog (TextField pre-filled "クローン2") → createBranch() →
  New TrackLane animates in below Main

Merge:
  Drag DraggableClip from クローン2 → drop on Main's MergeDropTarget →
  MergeConfirmDialog → mergeBranch() → クローン2 collapses via AnimatedContainer

Time travel:
  Drag ScrubCursor → highlight nearest commit →
  onPanEnd: checkoutCommit(sha) →
  Banner overlay: "閲覧モード: 2024-03-15のスナップショット" + "戻る" button
```

---

## pubspec.yaml Key Dependencies

```yaml
dependencies:
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^3.3.1
  go_router: ^14.0.0
  process_run: ^1.2.0     # which() to locate git binary cross-platform
  watcher: ^1.1.0
  http: ^1.2.0
  flutter_secure_storage: ^9.0.0
  flutter_animate: ^4.5.0
  intl: ^0.19.0
  window_manager: ^0.4.0
  file_picker: ^8.0.0
  path: ^1.9.0
  path_provider: ^2.1.0
  shared_preferences: ^2.2.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^3.3.1
```

---

## macOS Entitlements (required for git subprocess + network)

Add to both `DebugProfile.entitlements` and `Release.entitlements`:
```xml
<key>com.apple.security.network.client</key><true/>
<key>com.apple.security.files.user-selected.read-write</key><true/>
```

---

## Build Sequence

| Phase | What | Days |
|-------|------|------|
| 0 | `flutter create`, pubspec, directory structure, theme, router | 1 |
| 1 | All models + `GitService` (full API) + unit tests | 2–3 |
| 2 | `FileWatcherService` + auto-commit pipeline + providers | 4 |
| 3 | Timeline canvas: ruler, track lanes, InteractiveViewer, scrub cursor | 5–7 |
| 4 | Glass layer clips: `LayerClipPainter`, hover panel, viewport culling | 8–9 |
| 5 | Clone creation dialog + new track animation + drag-merge flow + collapse | 10–11 |
| 6 | Pro mode: log panel, manual commit, SHA badges | 12 |
| 7 | Welcome screen, window manager title, Japanese font polish | 13–14 |
| 8 | Windows/Linux testing, responsive layout | 15–16 |

---

## Verification

1. `flutter run -d macos` — app launches with welcome screen
2. Pick a folder containing files → git repo initializes, timeline shows initial glass clip
3. Edit a file in Finder → within 2s, new layer clip appears on timeline
4. Hover clip → info panel slides in with correct metadata
5. Drag scrub cursor → ScrubCursor moves, nearest commit highlights
6. Hover a clip → "ここでクローンを作成" → dialog → new track lane appears
7. Edit files on clone track → new clips appear on that track
8. Drag clone's latest clip to Main → merge dialog → confirm → clone collapses
9. Toggle Pro/Normal mode → log panel visibility changes; SHA badges appear/disappear
10. `flutter test` — unit tests for `GitService` pass against temp repo
