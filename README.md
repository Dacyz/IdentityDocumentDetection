# Identity Document Detection
Use tensor flow lite for detect identity documents on mobile devices

## Platform Support
> NOTE: The package maybe add support on future.

|             | Android | iOS   | macOS  | Windows | Linux |
|-------------|---------|-------|--------|---------|-------|
| **Support** | ✔ | ✔ | ✖ | ✖ | ✖ | 

## Features

Use this plugin in your Flutter app to:

* Not required network connection.
* Run on single image and real time.
* **Detect type** of a card.
* **Detect side** of document.
* **Detect position** on image.

> on future must detect brightness and sharpness

## Getting started

1.  Add `identity_document_detection` to your `pubspec.yaml`:

    ```yaml
    dependencies:
      identity_document_detection: latest_version
    ```

2.  Run `flutter pub get` to install.

## Usage

You have 2 ways to use it:
1. Using the `IdentityDetector` widget
```dart
class DetectorPage extends StatelessWidget {
  const DetectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IdentityDetector(
        options: IDOptions(
          confidence: 0.85,
          detection: IDTypeDetection.multiple,
          onDocumentDetect: (recognitions) {
            // TODO: Add your own logic here
          },
        ),
      ),
    );
  }
}
```
2. Creating `IDController` and initializing it

```dart
final detector = await IDController.initialize(widget.options);
_detector = detector;
_subscription = detector.stream.listen((values) {
  final painter = ObjectDetectorPainter(values);
  _customPaint = CustomPaint(painter: painter);
  setState(() {});
});
```
Callback to receive each frame `CameraImage` perform inference on it
```dart
void onImageAvailable(CameraImage cameraImage) async {
  _detector?.processFrame(cameraImage);
}
```
And for dispose you should use
```dart
_detector?.stop();
```

> [!IMPORTANT]
> For now the package adds a high weight to the project, it must be taken into
> consideration when taking it to stores, this will improve in the future.

## Coming soon
* **Detect brightness** on image.
* **Detect sharpness** on document.
