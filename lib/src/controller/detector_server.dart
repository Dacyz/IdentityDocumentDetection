part of 'package:identity_document_detection/src/controller/detector_service.dart';

/// The portion of the [IDController] that runs on the background isolate.
///
/// This is where we use the new feature Background Isolate Channels, which
/// allows us to use plugins from background isolates.
class _DetectorServer {
  /// Input size of image (height = width = 320)
  static const int mlModelInputSize = 320;

  /// Result confidence threshold
  late Interpreter _interpreter;
  List<String> _labels = [];

  _DetectorServer(this._sendPort);

  final SendPort _sendPort;

  // ----------------------------------------------------------------------
  // Here the plugin is used from the background isolate.
  // ----------------------------------------------------------------------

  /// The main entrypoint for the background isolate sent to [Isolate.spawn].
  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });
    // receivePort.sendPort - used by UI isolate to send commands to the service receiverPort
    sendPort.send(_Command(_Codes.init, args: [receivePort.sendPort]));
  }

  /// Handle the [command] received from the [ReceivePort].
  Future<void> _handleCommand(_Command command) async {
    switch (command.code) {
      case _Codes.init:
        // ----------------------------------------------------------------------
        // The [RootIsolateToken] is required for
        // [BackgroundIsolateBinaryMessenger.ensureInitialized] and must be
        // obtained on the root isolate and passed into the background isolate via
        // a [SendPort].
        // ----------------------------------------------------------------------
        RootIsolateToken rootIsolateToken = command.args?[0] as RootIsolateToken;
        // ----------------------------------------------------------------------
        // [BackgroundIsolateBinaryMessenger.ensureInitialized] for each
        // background isolate that will use plugins. This sets up the
        // [BinaryMessenger] that the Platform Channels will communicate with on
        // the background isolate.
        // ----------------------------------------------------------------------
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        _labels = command.args?[2] as List<String>;
        _sendPort.send(const _Command(_Codes.ready));
        break;
      case _Codes.detect:
        _sendPort.send(const _Command(_Codes.busy));
        _convertCameraImage(command.args?[0] as CameraImage);
        break;
      default:
        break;
    }
  }

  void _convertCameraImage(CameraImage cameraImage) async {
    var image = await convertCameraImageToImage(cameraImage);
    if (image == null) return;
    if (Platform.isAndroid) {
      image = img.copyRotate(image, angle: 90);
    }
    final results = analyzeImage(image);
    _sendPort.send(_Command(_Codes.result, args: results));
  }

  List<IdentityDocument> analyzeImage(img.Image image) {
    /// Pre-process the image
    final imageInput = _resize(image);
    final imageMatrix = _createMatrix(imageInput);
    final output = _runInference(imageMatrix);
    // Get results
    final scores = _getScores(output);
    final locations = _getLocations(output);
    final classes = _getClasses(output);
    final numberOfDetections = _getNumberOfDetections(output);
    // Generate classification
    final classification = List.generate(numberOfDetections, (i) => _labels[classes[i]]);

    /// Generate recognitions
    return List.generate(numberOfDetections, (i) {
      // Prediction score
      var score = scores[i];
      // Label string
      var label = classification[i];
      // Location
      var location = locations[i];
      return IdentityDocument(i, label, score, location);
    });
  }

  /// Resizing image for model [300, 300]
  img.Image _resize(img.Image image) {
    return img.copyResize(
      image,
      width: mlModelInputSize,
      height: mlModelInputSize,
    );
  }

  /// Creating matrix representation, [300, 300, 3]
  List<List<List<num>>> _createMatrix(img.Image imageInput) {
    return List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );
  }

  List<double> _getScores(List<List<Object>> output) => output.first.first as List<double>;

  List<Rect> _getLocations(List<List<Object>> output) {
    final locationsRaw = output.elementAt(1).first as List<List<double>>;
    return locationsRaw
        .map((list) => list.map((value) => (value * mlModelInputSize)).toList())
        .map((rect) => Rect.fromLTRB(rect[1], rect[0], rect[3], rect[2]))
        .toList();
  }

  List<int> _getClasses(List<List<Object>> output) {
    final classesRaw = output.last.first as List<double>;
    return classesRaw.map((value) => value.toInt()).toList();
  }

  int _getNumberOfDetections(List<List<Object>> output) {
    final numberOfDetectionsRaw = output[2].first as double;
    return numberOfDetectionsRaw.toInt();
  }

  /// Object detection main function
  List<List<Object>> _runInference(List<List<List<num>>> imageMatrix) {
    // Set input tensor [1, 320, 320, 3]
    final input = [imageMatrix];

    // Set output tensor
    // Locations: [1, 10, 4]
    // Classes: [1, 10],
    // Scores: [1, 10],
    // Number of detections: [1]
    final output = {
      0: [List<double>.filled(25, 0.0)],
      1: [List<List<double>>.filled(25, List<double>.filled(4, 0.0))],
      2: [0.0],
      3: [List<double>.filled(25, 0.0)],
    };

    _interpreter.runForMultipleInputs([input], output);
    return output.values.toList();
  }
}
