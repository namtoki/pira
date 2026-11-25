import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as mlkit;

import '../pose/pose_definition.dart';

const _typeMap = {
  Landmark.nose: mlkit.PoseLandmarkType.nose,
  Landmark.leftShoulder: mlkit.PoseLandmarkType.leftShoulder,
  Landmark.rightShoulder: mlkit.PoseLandmarkType.rightShoulder,
  Landmark.leftWrist: mlkit.PoseLandmarkType.leftWrist,
  Landmark.rightWrist: mlkit.PoseLandmarkType.rightWrist,
  Landmark.leftHip: mlkit.PoseLandmarkType.leftHip,
  Landmark.rightHip: mlkit.PoseLandmarkType.rightHip,
  Landmark.leftKnee: mlkit.PoseLandmarkType.leftKnee,
  Landmark.rightKnee: mlkit.PoseLandmarkType.rightKnee,
  Landmark.leftAnkle: mlkit.PoseLandmarkType.leftAnkle,
  Landmark.rightAnkle: mlkit.PoseLandmarkType.rightAnkle,
};

/// ML Kit の検出結果を判定用の座標に変換する
Map<Landmark, Point> toLandmarks(mlkit.Pose pose) => {
      for (final e in _typeMap.entries)
        if (pose.landmarks[e.value] case final lm?) e.key: Point(lm.x, lm.y, lm.likelihood),
    };
