/** MediaPipe Pose のランドマーク（座標は画像サイズで正規化された 0〜1） */
export interface Landmark {
  x: number;
  y: number;
  z: number;
  visibility?: number;
}

/** 判定に使う指標の名前（実装は src/metrics.ts） */
export type MetricName =
  | "torsoTiltDeg"
  | "kneeDrop"
  | "ankleDrop"
  | "kneeSpread"
  | "wristDrop"
  | "wristOffsetX"
  | "headOffsetX";

/** ポーズのチェック項目 1 つ分。値が [min, max] に入っていれば OK */
export interface PoseCheck {
  id: string;
  label: string;
  metric: MetricName;
  min?: number;
  max?: number;
  /** min を下回ったときの指摘 */
  tooLow?: string;
  /** max を上回ったときの指摘 */
  tooHigh?: string;
}

export interface PoseDefinition {
  id: string;
  name: string;
  /** カメラの置き方の案内 */
  cameraGuide: string;
  /** これらのランドマークの visibility が低いときは判定しない */
  requiredLandmarks: number[];
  minVisibility: number;
  checks: PoseCheck[];
}
