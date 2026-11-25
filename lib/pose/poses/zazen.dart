import '../pose_definition.dart';

/// 座禅（あぐら / 結跏趺坐・半跏趺坐）
///
/// カメラは体の正面。長さはすべて「胴の長さ（肩の中点〜腰の中点）」を 1 とした比率。
/// 値は初期値の目安で、実機で試しながら調整する。
const zazen = PoseDefinition(
  id: 'zazen',
  name: '座禅',
  cameraGuide: 'スマホを体の正面、床に近い高さに置いて、全身が映るようにしてください',
  requiredLandmarks: [
    Landmark.leftShoulder,
    Landmark.rightShoulder,
    Landmark.leftHip,
    Landmark.rightHip,
    Landmark.leftKnee,
    Landmark.rightKnee,
  ],
  minLikelihood: 0.5,
  checks: [
    PoseCheck(
      id: 'upright',
      label: '背すじ',
      metric: Metric.torsoTiltDeg,
      max: 20,
      tooHigh: '背すじをまっすぐ伸ばして',
    ),
    PoseCheck(
      id: 'seated',
      label: '床に座っている',
      metric: Metric.kneeDrop,
      max: 0.45,
      tooHigh: '床に座って、脚を組んでください',
    ),
    PoseCheck(
      id: 'legsFolded',
      label: '脚を組んでいる',
      metric: Metric.ankleDrop, // 足首が見えないときは省略
      max: 0.6,
      tooHigh: '脚を組んでください',
    ),
    PoseCheck(
      id: 'kneesOpen',
      label: 'ひざが開いている',
      metric: Metric.kneeSpread,
      min: 0.7,
      tooLow: 'ひざを左右に開いて、脚を組んでください',
    ),
    PoseCheck(
      id: 'handsLow',
      label: '手の高さ',
      metric: Metric.wristDrop,
      min: 0.6,
      tooLow: '手はおなかの前、足の上で組んでください',
    ),
    PoseCheck(
      id: 'handsCenter',
      label: '手の位置',
      metric: Metric.wristOffsetX,
      max: 0.5,
      tooHigh: '手は体の中心で組んでください',
    ),
    PoseCheck(
      id: 'head',
      label: '頭の位置',
      metric: Metric.headOffsetX,
      max: 0.35,
      tooHigh: '頭をまっすぐにしてください',
    ),
  ],
);
