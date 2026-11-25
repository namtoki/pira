// MediaPipe の wasm を public/ にコピーして、CDN なしで配信できるようにする
import { cpSync, mkdirSync } from "node:fs";
const src = "node_modules/@mediapipe/tasks-vision/wasm";
const dest = "public/mediapipe/wasm";
mkdirSync(dest, { recursive: true });
cpSync(src, dest, { recursive: true });
console.log(`copied ${src} -> ${dest}`);
