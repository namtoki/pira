import 'dart:math' as math;

import 'pose_definition.dart';

/// 任意項目（足首・手首・鼻）の信頼度の下限。下回ると指標は null（判定を省略）。
const optionalMinLikelihood = 0.3;

Point _mid(Point a, Point b) => Point((a.x + b.x) / 2, (a.y + b.y) / 2);
double _dist(Point a, Point b) => math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

/// 各部位の座標から指標を計算する。肩・腰・ひざは必ずある前提。
Map<Metric, double?> computeMetrics(Map<Landmark, Point> p) {
  bool visible(List<Landmark> ids) =>
      ids.every((id) => (p[id]?.likelihood ?? 0) >= optionalMinLikelihood);

  final shoulder = _mid(p[Landmark.leftShoulder]!, p[Landmark.rightShoulder]!);
  final hip = _mid(p[Landmark.leftHip]!, p[Landmark.rightHip]!);
  final knee = _mid(p[Landmark.leftKnee]!, p[Landmark.rightKnee]!);
  var torso = _dist(shoulder, hip);
  if (torso == 0) torso = 1;

  // 腰→肩 のベクトルと「真上」の角度
  final tilt = math.atan2((shoulder.x - hip.x).abs(), hip.y - shoulder.y) * 180 / math.pi;

  final anklesVisible = visible([Landmark.leftAnkle, Landmark.rightAnkle]);
  final wristsVisible = visible([Landmark.leftWrist, Landmark.rightWrist]);
  final ankle = anklesVisible ? _mid(p[Landmark.leftAnkle]!, p[Landmark.rightAnkle]!) : null;
  final wrist = wristsVisible ? _mid(p[Landmark.leftWrist]!, p[Landmark.rightWrist]!) : null;
  final nose = visible([Landmark.nose]) ? p[Landmark.nose] : null;

  return {
    Metric.torsoTiltDeg: tilt,
    Metric.kneeDrop: (knee.y - hip.y) / torso,
    Metric.ankleDrop: ankle == null ? null : (ankle.y - hip.y) / torso,
    Metric.kneeSpread: _dist(p[Landmark.leftKnee]!, p[Landmark.rightKnee]!) / torso,
    Metric.wristDrop: wrist == null ? null : (wrist.y - shoulder.y) / torso,
    Metric.wristOffsetX: wrist == null ? null : (wrist.x - hip.x).abs() / torso,
    Metric.headOffsetX: nose == null ? null : (nose.x - shoulder.x).abs() / torso,
  };
}
