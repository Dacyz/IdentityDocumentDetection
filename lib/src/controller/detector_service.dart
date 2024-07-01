// Copyright 2023 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:identity_document_detection/src/controller/utils/image_utils.dart';
import 'package:identity_document_detection/src/model/identity_document.dart';
import 'package:identity_document_detection/src/model/options.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

part 'package:identity_document_detection/src/model/command.dart';
part 'package:identity_document_detection/src/controller/detector_server.dart';

///////////////////////////////////////////////////////////////////////////////
// **WARNING:** This is not production code and is only intended to be used for
// demonstration purposes.
//
// The following Detector example works by spawning a background isolate and
// communicating with it over Dart's SendPort API. It is presented below as a
// demonstration of the feature "Background Isolate Channels" and shows using
// plugins from a background isolate. The [Detector] operates on the root
// isolate and the [_DetectorServer] operates on a background isolate.
//
// Here is an example of the protocol they use to communicate:
//
//  _________________                         ________________________
//  [:Detector]                               [:_DetectorServer]
//  -----------------                         ------------------------
//         |                                              |
//         |<---------------(init)------------------------|
//         |----------------(init)----------------------->|
//         |<---------------(ready)---------------------->|
//         |                                              |
//         |----------------(detect)--------------------->|
//         |<---------------(busy)------------------------|
//         |<---------------(result)----------------------|
//         |                 . . .                        |
//         |----------------(detect)--------------------->|
//         |<---------------(busy)------------------------|
//         |<---------------(result)----------------------|
//
///////////////////////////////////////////////////////////////////////////////

/// A Simple Detector that handles object detection via Service
///
/// All the heavy operations like pre-processing, detection, ets,
/// are executed in a background isolate.
/// This class just sends and receives messages to the isolate.
///
class IDController {
  static const String _modelPath = 'packages/identity_document_detection/assets/model/document.tflite';
  static const String _labelPath = 'packages/identity_document_detection/assets/model/classes.txt';

  IDController._(this._isolate, this._interpreter, this._labels, this._options);

  final Isolate _isolate;
  late final Interpreter _interpreter;
  late final List<String> _labels;
  final IDOptions _options;

  // To be used by detector (from UI) to send message to our Service ReceivePort
  late final SendPort _sendPort;

  bool _isReady = false;

  // // Similarly, StreamControllers are stored in a queue so they can be handled
  // // asynchronously and serially.
  final StreamController<List<IdentityDocument>> _stream = StreamController<List<IdentityDocument>>();
  Stream<List<IdentityDocument>> get stream => _stream.stream;

  /// Open the database at [path] and launch the server on a background isolate..
  static Future<IDController> initialize([IDOptions confidence = IDOptions.byDefault]) async {
    final ReceivePort receivePort = ReceivePort();
    // sendPort - To be used by service Isolate to send message to our ReceiverPort
    final Isolate isolate = await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);
    final model = await _loadModel();
    final labels = await _loadLabels();
    final IDController result = IDController._(isolate, model, labels, confidence);
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });
    return result;
  }

  static Future<Interpreter> _loadModel() async {
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    return Interpreter.fromAsset(
      _modelPath,
      options: interpreterOptions,
    );
  }

  static Future<List<String>> _loadLabels() async {
    final fileContent = await rootBundle.loadString(_labelPath);
    final labels = fileContent.split('\n');
    return labels;
  }

  /// Starts CameraImage processing
  void processFrame(CameraImage cameraImage) {
    if (_isReady) {
      _sendPort.send(_Command(_Codes.detect, args: [cameraImage]));
    }
  }

  /// Handler invoked when a message is received from the port communicating
  /// with the database server.
  void _handleCommand(_Command command) {
    switch (command.code) {
      case _Codes.init:
        _sendPort = command.args?[0] as SendPort;
        // ----------------------------------------------------------------------
        // Before using platform channels and plugins from background isolates we
        // need to register it with its root isolate. This is achieved by
        // acquiring a [RootIsolateToken] which the background isolate uses to
        // invoke [BackgroundIsolateBinaryMessenger.ensureInitialized].
        // ----------------------------------------------------------------------
        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(_Codes.init, args: [
          rootIsolateToken,
          _interpreter.address,
          _labels,
        ]));
      case _Codes.ready:
        _isReady = true;
        break;
      case _Codes.busy:
        _isReady = false;
        break;
      case _Codes.result:
        _isReady = true;
        var docs = command.args as List<IdentityDocument>;
        if (_options.detection == IDTypeDetection.multiple) {
          docs = docs.where((recognition) => recognition.score > _options.confidence).toList();
        } else {
          docs = [docs.reduce((A, B) => A.score > B.score && B.score > _options.confidence ? A : B)];
          if (docs.first.score < _options.confidence) docs = [];
        }
        _options.onDocumentDetect?.call(docs);
        _stream.add(docs);
        break;
      default:
        break;
    }
  }

  /// Kills the background isolate and its detector server.
  void stop() {
    _isolate.kill();
  }
}
