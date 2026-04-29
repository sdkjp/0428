// Conditional export: web build uses JS interop, native builds use dart:io
export 'git_service_native.dart'
    if (dart.library.js_interop) 'git_service_web.dart';
