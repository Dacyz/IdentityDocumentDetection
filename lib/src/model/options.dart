import 'package:identity_document_detection/src/model/identity_document.dart';

// Options for object detection
enum IDTypeDetection { singular, multiple }

/// Options for ID detection
class IDOptions {
  const IDOptions({
    required this.confidence,
    this.detection = IDTypeDetection.multiple,
    this.onDocumentDetect,
  });
  final double confidence;
  final IDTypeDetection detection;
  final void Function(List<IdentityDocument> documents)? onDocumentDetect;

  static const IDOptions byDefault = IDOptions(confidence: 0.75);
}
