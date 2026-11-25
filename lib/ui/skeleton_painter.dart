import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:material_ui/material_ui.dart';

const _connections = [
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
  (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
  (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
  (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
  (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
  (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
];

/// カメラ映像の上に骨格を描く
class SkeletonPainter extends CustomPainter {
  SkeletonPainter({
    required this.pose,
    required this.imageSize,
    required this.mirror,
    required this.color,
  });

  final Pose pose;

  /// ML Kit 座標系（縦向き）での画像サイズ
  final Size imageSize;

  /// 前面カメラのプレビューは左右反転して表示されるので、点も反転する
  final bool mirror;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / imageSize.width;
    final sy = size.height / imageSize.height;
    Offset? at(PoseLandmarkType t) {
      final lm = pose.landmarks[t];
      if (lm == null || lm.likelihood < 0.3) return null;
      final x = lm.x * sx;
      return Offset(mirror ? size.width - x : x, lm.y * sy);
    }

    final line = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in _connections) {
      final pa = at(a);
      final pb = at(b);
      if (pa != null && pb != null) canvas.drawLine(pa, pb, line);
    }
    final dot = Paint()..color = color;
    for (final t in PoseLandmarkType.values) {
      final p = at(t);
      if (p != null) canvas.drawCircle(p, 5, dot);
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter old) =>
      old.pose != pose || old.color != color || old.mirror != mirror;
}
