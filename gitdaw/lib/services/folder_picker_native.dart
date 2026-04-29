import 'package:file_picker/file_picker.dart';

Future<String?> pickFolderPath() =>
    FilePicker.getDirectoryPath(dialogTitle: 'フォルダを選択してください');
