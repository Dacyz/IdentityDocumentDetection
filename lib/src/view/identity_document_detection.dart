import 'package:flutter/widgets.dart';
import 'package:identity_document_detection/src/model/screen_params.dart';
import 'package:identity_document_detection/src/view/widgets/detector_widget.dart';

class IDView extends StatefulWidget {
  const IDView({super.key});

  @override
  State<IDView> createState() => _IDViewState();
}

class _IDViewState extends State<IDView> {
  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return const DetectorWidget();
  }
}
