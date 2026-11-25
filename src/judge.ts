import type { Landmark, PoseDefinition } from "./poses/types.ts";
import { computeMetrics } from "./metrics.ts";

export interface CheckResult {
  id: string;
  label: string;
  value: number | null;
  ok: boolean;
  message?: string;
}

export type Judgement =
  | { status: "noPerson"; message: string }
  | { status: "lowVisibility"; message: string }
  | { status: "judged"; ok: boolean; checks: CheckResult[]; message?: string };

/** 1 フレーム分の判定 */
export function judgePose(
  pose: PoseDefinition,
  lms: Landmark[] | undefined,
  width: number,
  height: number,
): Judgement {
  if (!lms || lms.length < 33) {
    return { status: "noPerson", message: "人が映っていません" };
  }
  const visible = pose.requiredLandmarks.every(
    (i) => (lms[i].visibility ?? 1) >= pose.minVisibility,
  );
  if (!visible) {
    return { status: "lowVisibility", message: "全身が映るようにしてください" };
  }

  const metrics = computeMetrics(lms, width, height);
  const checks: CheckResult[] = pose.checks.map((c) => {
    const value = metrics[c.metric];
    if (value === null) return { id: c.id, label: c.label, value, ok: true }; // 見えない項目は省略
    if (c.min !== undefined && value < c.min)
      return { id: c.id, label: c.label, value, ok: false, message: c.tooLow };
    if (c.max !== undefined && value > c.max)
      return { id: c.id, label: c.label, value, ok: false, message: c.tooHigh };
    return { id: c.id, label: c.label, value, ok: true };
  });
  const firstNg = checks.find((c) => !c.ok);
  return { status: "judged", ok: !firstNg, checks, message: firstNg?.message };
}

/**
 * 判定のチラつきを抑える。OK/NG が一定時間続いたときだけ表示を切り替える。
 */
export class Stabilizer {
  private shown = false;
  private candidate = false;
  private since = 0;

  private holdMs: number;

  constructor(holdMs = 400) {
    this.holdMs = holdMs;
  }

  update(ok: boolean, now: number): boolean {
    if (ok !== this.candidate) {
      this.candidate = ok;
      this.since = now;
    }
    if (this.candidate !== this.shown && now - this.since >= this.holdMs) {
      this.shown = this.candidate;
    }
    return this.shown;
  }
}
