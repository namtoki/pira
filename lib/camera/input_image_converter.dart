import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// カメラのフレームを ML Kit の入力に変換する。
/// 画面は縦向き固定なので、端末の向きは常に portraitUp として扱う。
InputImage? inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
  final sensor = camera.sensorOrientation;
  final InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensor);
  } else {
    // 縦向き（portraitUp = 0°）での補正
    const deviceRotation = 0;
    final compensation = camera.lensDirection == CameraLensDirection.front
        ? (sensor + deviceRotation) % 360
        : (sensor - deviceRotation + 360) % 360;
    rotation = InputImageRotationValue.fromRawValue(compensation);
  }
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
  if (format == null) return null;
  if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
  if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
  if (image.planes.length != 1) return null;

  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}

/// ML Kit の座標系（回転後の縦向き画像）でのサイズ
Size uprightImageSize(InputImage image) {
  final m = image.metadata!;
  final swap = m.rotation == InputImageRotation.rotation90deg ||
      m.rotation == InputImageRotation.rotation270deg;
  return swap ? Size(m.size.height, m.size.width) : m.size;
}
