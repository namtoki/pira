import { test } from "node:test";
import assert from "node:assert/strict";
import { judgePose } from "../src/judge.ts";
import { zazen } from "../src/poses/zazen.ts";
import type { Landmark } from "../src/poses/types.ts";

const W = 1000;
const H = 1000;

/** ピクセル座標で指定した点から 33 点のランドマークを作る */
function makePose(points: Record<number, [number, number]>): Landmark[] {
  const lms: Landmark[] = Array.from({ length: 33 }, () => ({ x: 0.5, y: 0.5, z: 0, visibility: 0.1 }));
  for (const [i, [x, y]] of Object.entries(points)) {
    lms[Number(i)] = { x: x / W, y: y / H, z: 0, visibility: 0.95 };
  }
  return lms;
}

// 正面から見た座禅（胴の長さ 300px）
const zazenPose = makePose({
  0: [500, 250],
  11: [430, 350], 12: [570, 350],
  15: [480, 680], 16: [520, 680],
  23: [460, 650], 24: [540, 650],
  25: [320, 700], 26: [680, 700],
  27: [450, 720], 28: [550, 720],
});

// 立っている
const standing = makePose({
  0: [500, 150],
  11: [430, 250], 12: [570, 250],
  15: [400, 550], 16: [600, 550],
  23: [460, 550], 24: [540, 550],
  25: [460, 750], 26: [540, 750],
  27: [460, 950], 28: [540, 950],
});

// 椅子に座っている（正面）: ひざは腰と同じ高さに見えるが、足首は下
const chair = makePose({
  0: [500, 150],
  11: [430, 250], 12: [570, 250],
  15: [470, 560], 16: [530, 560],
  23: [460, 550], 24: [540, 550],
  25: [380, 600], 26: [620, 600],
  27: [380, 900], 28: [620, 900],
});

test("座禅のポーズは OK", () => {
  const j = judgePose(zazen, zazenPose, W, H);
  assert.equal(j.status, "judged");
  assert.ok(j.status === "judged" && j.ok, JSON.stringify(j));
});

test("立っているときは NG", () => {
  const j = judgePose(zazen, standing, W, H);
  assert.ok(j.status === "judged" && !j.ok);
});

test("椅子に座っているときは NG", () => {
  const j = judgePose(zazen, chair, W, H);
  assert.ok(j.status === "judged" && !j.ok);
});

test("手を上げていると NG", () => {
  const lms = zazenPose.map((p) => ({ ...p }));
  lms[15] = { ...lms[15], y: 0.3 };
  lms[16] = { ...lms[16], y: 0.3 };
  const j = judgePose(zazen, lms, W, H);
  assert.ok(j.status === "judged" && !j.ok);
  assert.equal(j.status === "judged" && j.message, "手はおなかの前、足の上で組んでください");
});

test("足首が見えなくても、ほかが合っていれば OK", () => {
  const lms = zazenPose.map((p) => ({ ...p }));
  lms[27] = { ...lms[27], visibility: 0.05 };
  lms[28] = { ...lms[28], visibility: 0.05 };
  const j = judgePose(zazen, lms, W, H);
  assert.ok(j.status === "judged" && j.ok);
});

test("腰やひざが見えないときは判定しない", () => {
  const lms = zazenPose.map((p) => ({ ...p }));
  lms[25] = { ...lms[25], visibility: 0.1 };
  assert.equal(judgePose(zazen, lms, W, H).status, "lowVisibility");
});

test("人がいないとき", () => {
  assert.equal(judgePose(zazen, undefined, W, H).status, "noPerson");
});
