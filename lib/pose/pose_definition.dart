/// 判定に使う指標（計算は metrics.dart）
enum Metric {
  /// 胴（腰→肩）の垂直からの傾き [度]
  torsoTiltDeg,

  /// ひざが腰よりどれだけ下にあるか（胴の長さ比）
  kneeDrop,

  /// 足首が腰よりどれだけ下にあるか（胴の長さ比）
  ankleDrop,

  /// 左右のひざの間隔（胴の長さ比）
  kneeSpread,

  /// 手首が肩よりどれだけ下にあるか（胴の長さ比）
  wristDrop,

  /// 手首の中点と体の中心の横ずれ（胴の長さ比）
  wristOffsetX,

  /// 鼻と肩の中点の横ずれ（胴の長さ比）
  headOffsetX,
}

/// チェック項目 1 つ分。値が [min, max] に入っていれば OK。
class PoseCheck {
  const PoseCheck({
    required this.id,
    required this.label,
    required this.metric,
    this.min,
    this.max,
    this.tooLow,
    this.tooHigh,
  });

  final String id;
  final String label;
  final Metric metric;
  final double? min;
  final double? max;

  /// min を下回ったときの指摘
  final String? tooLow;

  /// max を上回ったときの指摘
  final String? tooHigh;
}

class PoseDefinition {
  const PoseDefinition({
    required this.id,
    required this.name,
    required this.cameraGuide,
    required this.requiredLandmarks,
    required this.minLikelihood,
    required this.checks,
  });

  final String id;
  final String name;

  /// カメラの置き方の案内
  final String cameraGuide;

  /// これらの部位の信頼度が低いときは判定しない
  final List<Landmark> requiredLandmarks;
  final double minLikelihood;
  final List<PoseCheck> checks;
}

/// 判定に使う部位。ML Kit / MediaPipe の 33 点のうち必要なものだけ。
enum Landmark {
  nose,
  leftShoulder,
  rightShoulder,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

/// 1 点分の座標（画像のピクセル座標、y は下向きが正）と信頼度
class Point {
  const Point(this.x, this.y, [this.likelihood = 1]);
  final double x;
  final double y;
  final double likelihood;
}
