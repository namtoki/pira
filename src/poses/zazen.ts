import type { PoseDefinition } from "./types.ts";
import { LM } from "../landmarks.ts";

/**
 * 座禅（あぐら / 結跏趺坐・半跏趺坐）
 * カメラは体の正面。長さはすべて「胴の長さ（肩の中点〜腰の中点）」を 1 とした比率。
 * 画像の y は下向きが正。値は初期値の目安で、実機で試しながら調整する。
 */
export const zazen: PoseDefinition = {
  id: "zazen",
  name: "座禅",
  cameraGuide: "カメラを体の正面、床に近い高さに置いて、全身が映るようにしてください",
  requiredLandmarks: [
    LM.LEFT_SHOULDER, LM.RIGHT_SHOULDER,
    LM.LEFT_HIP, LM.RIGHT_HIP,
    LM.LEFT_KNEE, LM.RIGHT_KNEE,
  ],
  minVisibility: 0.5,
  checks: [
    {
      id: "upright",
      label: "背すじ",
      metric: "torsoTiltDeg", // 胴の傾き（垂直からの角度）
      max: 20,
      tooHigh: "背すじをまっすぐ伸ばして",
    },
    {
      id: "seated",
      label: "床に座っている",
      metric: "kneeDrop", // ひざが腰よりどれだけ下にあるか
      max: 0.45,
      tooHigh: "床に座って、脚を組んでください",
    },
    {
      id: "legsFolded",
      label: "脚を組んでいる",
      metric: "ankleDrop", // 足首が腰よりどれだけ下にあるか（足首が見えないときは省略）
      max: 0.6,
      tooHigh: "脚を組んでください",
    },
    {
      id: "kneesOpen",
      label: "ひざが開いている",
      metric: "kneeSpread", // 左右のひざの間隔
      min: 0.7,
      tooLow: "ひざを左右に開いて、脚を組んでください",
    },
    {
      id: "handsLow",
      label: "手の高さ",
      metric: "wristDrop", // 手首が肩よりどれだけ下にあるか
      min: 0.6,
      tooLow: "手はおなかの前、足の上で組んでください",
    },
    {
      id: "handsCenter",
      label: "手の位置",
      metric: "wristOffsetX", // 手首の中点が体の中心からどれだけ横にずれているか
      max: 0.5,
      tooHigh: "手は体の中心で組んでください",
    },
    {
      id: "head",
      label: "頭の位置",
      metric: "headOffsetX", // 鼻が肩の中点から横にずれていないか
      max: 0.35,
      tooHigh: "頭をまっすぐにしてください",
    },
  ],
};
