import type { Landmark, MetricName } from "./poses/types.ts";
import { LM } from "./landmarks.ts";

interface P { x: number; y: number }

const mid = (a: P, b: P): P => ({ x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 });
const dist = (a: P, b: P) => Math.hypot(a.x - b.x, a.y - b.y);

/** 任意項目（足首・手首・鼻）の visibility の下限。下回ると指標は null（判定を省略） */
const OPTIONAL_MIN_VISIBILITY = 0.3;

/**
 * ランドマーク（0〜1 の正規化座標）から各指標を計算する。
 * 縦横比の歪みをなくすため、画像のピクセルサイズで座標を戻してから計算する。
 */
export function computeMetrics(
  lms: Landmark[],
  width: number,
  height: number,
): Record<MetricName, number | null> {
  const px = (i: number): P => ({ x: lms[i].x * width, y: lms[i].y * height });
  const vis = (...ids: number[]) =>
    ids.every((i) => (lms[i].visibility ?? 1) >= OPTIONAL_MIN_VISIBILITY);

  const shoulder = mid(px(LM.LEFT_SHOULDER), px(LM.RIGHT_SHOULDER));
  const hip = mid(px(LM.LEFT_HIP), px(LM.RIGHT_HIP));
  const knee = mid(px(LM.LEFT_KNEE), px(LM.RIGHT_KNEE));
  const torso = dist(shoulder, hip) || 1;

  // 胴の傾き: 腰→肩 のベクトルと「真上」の角度
  const tilt =
    (Math.atan2(Math.abs(shoulder.x - hip.x), hip.y - shoulder.y) * 180) / Math.PI;

  const ankleDrop = vis(LM.LEFT_ANKLE, LM.RIGHT_ANKLE)
    ? (mid(px(LM.LEFT_ANKLE), px(LM.RIGHT_ANKLE)).y - hip.y) / torso
    : null;

  const wristsVisible = vis(LM.LEFT_WRIST, LM.RIGHT_WRIST);
  const wrist = mid(px(LM.LEFT_WRIST), px(LM.RIGHT_WRIST));

  return {
    torsoTiltDeg: tilt,
    kneeDrop: (knee.y - hip.y) / torso,
    ankleDrop,
    kneeSpread: dist(px(LM.LEFT_KNEE), px(LM.RIGHT_KNEE)) / torso,
    wristDrop: wristsVisible ? (wrist.y - shoulder.y) / torso : null,
    wristOffsetX: wristsVisible ? Math.abs(wrist.x - hip.x) / torso : null,
    headOffsetX: vis(LM.NOSE) ? Math.abs(px(LM.NOSE).x - shoulder.x) / torso : null,
  };
}
