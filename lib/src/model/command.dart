part of 'package:identity_document_detection/src/controller/detector_service.dart';

/// All the command codes that can be sent and received between [IDController] and
/// [_DetectorServer].
enum _Codes {
  init,
  busy,
  ready,
  detect,
  result,
}

/// A command sent between [IDController] and [_DetectorServer].
class _Command {
  const _Command(this.code, {this.args});

  final _Codes code;
  final List<Object>? args;
}