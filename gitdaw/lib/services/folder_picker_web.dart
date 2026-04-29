import 'dart:js_interop';

@JS('gitdaw.openDirectory')
external JSPromise<JSString?> _jsOpenDirectory();

Future<String?> pickFolderPath() async {
  final result = await _jsOpenDirectory().toDart;
  return result?.toDart;
}
