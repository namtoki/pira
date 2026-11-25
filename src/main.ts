import { FilesetResolver, PoseLandmarker } from "@mediapipe/tasks-vision";
import { judgePose, Stabilizer, type Judgement } from "./judge.ts";
import { zazen } from "./poses/zazen.ts";

const MODEL_URL =
  "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task";
const WASM_PATH = `${import.meta.env.BASE_URL}mediapipe/wasm`;

const pose = zazen;

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const video = $<HTMLVideoElement>("video");
const canvas = $<HTMLCanvasElement>("view");
const ctx = canvas.getContext("2d")!;
const badge = $("badge");
const statusEl = $("status");
const details = $<HTMLPreElement>("details");

let facingMode: "user" | "environment" = "user";
let stream: MediaStream | null = null;
let landmarker: PoseLandmarker | null = null;
const stabilizer = new Stabilizer(400);

function setStatus(text: string) {
  if (statusEl.textContent !== text) statusEl.textContent = text;
}

async function startCamera() {
  stream?.getTracks().forEach((t) => t.stop());
  stream = await navigator.mediaDevices.getUserMedia({
    audio: false,
    video: { facingMode, width: { ideal: 1280 }, height: { ideal: 720 } },
  });
  video.srcObject = stream;
  await video.play();
  canvas.classList.toggle("mirror", facingMode === "user");
}

async function createLandmarker() {
  const fileset = await FilesetResolver.forVisionTasks(WASM_PATH);
  const options = (delegate: "GPU" | "CPU") => ({
    baseOptions: { modelAssetPath: MODEL_URL, delegate },
    runningMode: "VIDEO" as const,
    numPoses: 1,
  });
  try {
    return await PoseLandmarker.createFromOptions(fileset, options("GPU"));
  } catch (e) {
    console.warn("GPU が使えないため CPU で実行します", e);
    return await PoseLandmarker.createFromOptions(fileset, options("CPU"));
  }
}

function drawSkeleton(lms: { x: number; y: number; visibility?: number }[], color: string) {
  const w = canvas.width;
  const h = canvas.height;
  ctx.lineWidth = Math.max(3, w / 250);
  ctx.strokeStyle = color;
  ctx.fillStyle = color;
  for (const { start, end } of PoseLandmarker.POSE_CONNECTIONS) {
    const a = lms[start];
    const b = lms[end];
    if ((a.visibility ?? 1) < 0.3 || (b.visibility ?? 1) < 0.3) continue;
    ctx.beginPath();
    ctx.moveTo(a.x * w, a.y * h);
    ctx.lineTo(b.x * w, b.y * h);
    ctx.stroke();
  }
  for (const p of lms) {
    if ((p.visibility ?? 1) < 0.3) continue;
    ctx.beginPath();
    ctx.arc(p.x * w, p.y * h, ctx.lineWidth * 1.3, 0, Math.PI * 2);
    ctx.fill();
  }
}

function render(j: Judgement, ok: boolean) {
  badge.classList.toggle("on", ok);
  if (ok) setStatus(`${pose.name}のポーズです`);
  else if (j.status === "judged") setStatus(j.message ?? "");
  else setStatus(j.message);

  if (!details.hidden) {
    details.textContent =
      j.status === "judged"
        ? j.checks
            .map((c) => `${c.ok ? "○" : "×"} ${c.label}: ${c.value === null ? "—" : c.value.toFixed(2)}`)
            .join("\n")
        : j.message;
  }
}

let lastVideoTime = -1;
function loop() {
  requestAnimationFrame(loop);
  if (!landmarker || video.readyState < 2) return;
  if (video.currentTime === lastVideoTime) return;
  lastVideoTime = video.currentTime;

  const w = video.videoWidth;
  const h = video.videoHeight;
  if (canvas.width !== w || canvas.height !== h) {
    canvas.width = w;
    canvas.height = h;
  }
  ctx.drawImage(video, 0, 0, w, h);

  const now = performance.now();
  const result = landmarker.detectForVideo(video, now);
  const lms = result.landmarks[0];
  const j = judgePose(pose, lms, w, h);
  const ok = stabilizer.update(j.status === "judged" && j.ok, now);
  if (lms) drawSkeleton(lms, ok ? "#22c55e" : "#ffffff");
  render(j, ok);
}

$("switch").addEventListener("click", async () => {
  facingMode = facingMode === "user" ? "environment" : "user";
  try {
    await startCamera();
  } catch (e) {
    console.error(e);
    setStatus("カメラを切り替えられませんでした");
  }
});
$("debug").addEventListener("click", () => {
  details.hidden = !details.hidden;
});

async function main() {
  if (!navigator.mediaDevices?.getUserMedia) {
    setStatus("このブラウザではカメラが使えません（HTTPS で開いてください）");
    return;
  }
  try {
    await startCamera();
  } catch (e) {
    console.error(e);
    setStatus("カメラを使う許可をしてください");
    return;
  }
  setStatus("AI モデルを読み込んでいます…");
  requestAnimationFrame(loop);
  try {
    landmarker = await createLandmarker();
    setStatus(pose.cameraGuide);
  } catch (e) {
    console.error(e);
    setStatus("AI モデルを読み込めませんでした。通信環境を確認してください");
  }
}

main();
