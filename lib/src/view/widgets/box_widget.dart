import 'package:flutter/material.dart';
import 'package:identity_document_detection/src/model/identity_document.dart';
import 'dart:ui' as ui;

class ObjectDetectorPainter extends CustomPainter {
  ObjectDetectorPainter(this._objects);

  final List<IdentityDocument> _objects;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = const Color(0x99000000);
    final validation = _objects.length > 1;
    Paint currentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.grey;
    if (validation) {
      paint.color = Colors.redAccent;
      currentPaint.color = Colors.redAccent;
    }

    final verticalTopPoint = size.height * .10;
    final verticalBottomPoint = size.height * .90;
    final horizontalLeftPoint = size.width * .10;
    final horizontalRightPoint = size.width * .90;
    const augment = 32;

    for (final IdentityDocument detectedObject in _objects) {
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(textAlign: TextAlign.left, fontSize: 16, textDirection: TextDirection.ltr),
      );
      builder.pushStyle(ui.TextStyle(color: Colors.lightGreenAccent, background: background));
      if (detectedObject.label.isNotEmpty) {
        // final label = detectedObject.labels.reduce((a, b) => a.confidence > b.confidence ? a : b);
        builder.addText('${detectedObject.label} \n${detectedObject.score}');
        // builder.addText('${label.text} ${label.confidence}');
      }
      builder.pop();

      final left = detectedObject.renderLocation.left;
      final top = detectedObject.renderLocation.top;
      final right = detectedObject.renderLocation.right;

      bool isLeftCentered = left > size.width * .05 && left < size.width * .25;
      bool isRightCentered = right > size.width * .75 && right < size.width * 1.05;

      if (!validation) {
        currentPaint = currentPaint..color = isLeftCentered && isRightCentered ? Colors.lightGreenAccent : Colors.grey;
      }

      canvas.drawRect(detectedObject.renderLocation, paint);
      canvas.drawParagraph(
        builder.build()
          ..layout(ui.ParagraphConstraints(
            width: (right - left).abs(),
          )),
        Offset(right, top),
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
