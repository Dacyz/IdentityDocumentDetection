import 'package:flutter/material.dart';
import 'package:identity_document_detection/src/model/recognition.dart';
import 'dart:ui' as ui;


/// Individual bounding box
class BoxWidget extends StatelessWidget {
  final Recognition result;

  const BoxWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Color for bounding box
    Color color =
        Colors.primaries[(result.label.length + result.label.codeUnitAt(0) + result.id) % Colors.primaries.length];

    return Positioned(
      left: result.renderLocation.left,
      top: result.renderLocation.top,
      width: result.renderLocation.width,
      height: result.renderLocation.height,
      child: Container(
        width: result.renderLocation.width,
        height: result.renderLocation.height,
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 3), borderRadius: const BorderRadius.all(Radius.circular(2))),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(result.label),
                  Text(" ${result.score.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ObjectDetectorPainter extends CustomPainter {
  ObjectDetectorPainter(
    this._objects,
    // this.imageSize,
    // this.rotation,
    // this.cameraLensDirection,
  );

  final List<Recognition> _objects;
  // final Size imageSize;
  // final InputImageRotation rotation;
  // final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = const Color(0x99000000);
    Paint currentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.grey;

    final verticalTopPoint = size.height * .10;
    final verticalBottomPoint = size.height * .90;
    final horizontalLeftPoint = size.width * .10;
    final horizontalRightPoint = size.width * .90;
    const augment = 32;

    for (final Recognition detectedObject in _objects) {
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(textAlign: TextAlign.left, fontSize: 16, textDirection: TextDirection.ltr),
      );
      builder.pushStyle(ui.TextStyle(color: Colors.lightGreenAccent, background: background));
      if (detectedObject.label.isNotEmpty) {
        // final label = detectedObject.labels.reduce((a, b) => a.confidence > b.confidence ? a : b);
        builder.addText('${detectedObject.label} ');
        // builder.addText('${label.text} ${label.confidence}');
      }
      builder.pop();

      final left = detectedObject.renderLocation.left;
      final top = detectedObject.renderLocation.top;
      final right = detectedObject.renderLocation.right;
      final bottom = detectedObject.renderLocation.bottom;

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );

      bool isLeftCentered = left > size.width * .05 && left < size.width * .25;
      bool isRightCentered = right > size.width * .75 && right < size.width * 1.05;
      currentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = isLeftCentered && isRightCentered ? Colors.lightGreenAccent : Colors.grey;

      canvas.drawParagraph(
        builder.build()
          ..layout(ui.ParagraphConstraints(
            width: (right - left).abs(),
          )),
        Offset( left, top),
      );
    }

    // Primer esquina
    canvas.drawLine(
      Offset(
        horizontalLeftPoint + augment,
        verticalTopPoint,
      ),
      Offset(
        horizontalLeftPoint,
        verticalTopPoint,
      ),
      currentPaint,
    );
    canvas.drawLine(
      Offset(
        horizontalLeftPoint,
        verticalTopPoint,
      ),
      Offset(
        horizontalLeftPoint,
        verticalTopPoint + augment,
      ),
      currentPaint,
    );

    // Segunda esquina
    canvas.drawLine(
      Offset(
        horizontalLeftPoint,
        verticalBottomPoint - augment,
      ),
      Offset(
        horizontalLeftPoint,
        verticalBottomPoint,
      ),
      currentPaint,
    );
    canvas.drawLine(
      Offset(
        horizontalLeftPoint,
        verticalBottomPoint,
      ),
      Offset(
        horizontalLeftPoint + augment,
        verticalBottomPoint,
      ),
      currentPaint,
    );
    // Tercera esquina
    canvas.drawLine(
      Offset(
        horizontalRightPoint - augment,
        verticalBottomPoint,
      ),
      Offset(
        horizontalRightPoint,
        verticalBottomPoint,
      ),
      currentPaint,
    );
    canvas.drawLine(
      Offset(
        horizontalRightPoint,
        verticalBottomPoint,
      ),
      Offset(
        horizontalRightPoint,
        verticalBottomPoint - augment,
      ),
      currentPaint,
    );
    // Cuarta esquina
    canvas.drawLine(
      Offset(
        horizontalRightPoint,
        verticalTopPoint + augment,
      ),
      Offset(
        horizontalRightPoint,
        verticalTopPoint,
      ),
      currentPaint,
    );
    canvas.drawLine(
      Offset(
        horizontalRightPoint,
        verticalTopPoint,
      ),
      Offset(
        horizontalRightPoint - augment,
        verticalTopPoint,
      ),
      currentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
