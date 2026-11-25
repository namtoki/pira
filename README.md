# Pira（座禅チェック プロトタイプ）

スマホのカメラに映った人が **座禅のポーズ** をしていると、画面上部に **緑の ⭕️** を表示する Flutter アプリです。
いまは Android 向けにビルドしています。iOS にも対応できる構成です（後述）。

- 姿勢推定: Google ML Kit Pose Detection（`google_mlkit_pose_detection`、33 点のランドマーク）
- カメラ: `camera`
- 映像は端末の中だけで処理し、外部には送信しません

## 使い方

1. アプリを起動するとカメラが起動します（初回はカメラの許可を求められます）
2. スマホを体の **正面・床に近い高さ** に置き、全身が映るようにします
3. 座禅を組むと上部に緑の ⭕️ が出ます。外れているときは、直すポイントを日本語で表示します
4. 「カメラ切替」で前面/背面カメラを切り替え、「詳細」で各チェック項目の値を確認できます

## 判定の内容（`lib/pose/poses/zazen.dart`）

胴の長さ（肩の中点〜腰の中点）を 1 とした比率で判定します。値は目安なので、実機で「詳細」の数値を見ながら調整してください。

| 項目 | 指標 | 範囲 |
| --- | --- | --- |
| 背すじ | 胴の垂直からの傾き | 20° 以下 |
| 床に座っている | ひざが腰よりどれだけ下か | 0.45 以下 |
| 脚を組んでいる | 足首が腰よりどれだけ下か（見えないときは省略） | 0.6 以下 |
| ひざが開いている | 左右のひざの間隔 | 0.7 以上 |
| 手の高さ | 手首が肩よりどれだけ下か | 0.6 以上 |
| 手の位置 | 手首の中点と体の中心の横ずれ | 0.5 以下 |
| 頭の位置 | 鼻と肩の中点の横ずれ | 0.35 以下 |

- 肩・腰・ひざが十分に見えないときは判定せず「全身が映るようにしてください」と表示します
- 表示のチラつきを抑えるため、OK/NG が 0.4 秒続いたときに切り替えます
- 骨格の点だけで判定しているため、呼吸や目線、骨盤の細かな傾きなどは判定できません

## APK の入手

GitHub Actions（`.github/workflows/android.yml`）が push ごとに APK をビルドします。
Actions の実行結果ページの「Artifacts」から `pira-apk` をダウンロードし、Android にインストールしてください（「提供元不明のアプリ」の許可が必要です）。

## 開発

Flutter 3.50 以上が必要です。

```sh
flutter pub get
flutter test               # 判定ロジックのテスト
flutter run                # USB 接続した実機で起動
flutter build apk --release
```

### iOS 対応のメモ

Xcode のある Mac で行います（この構成はまだ iOS 実機で試していません）。

- 最低 iOS 15.0、カメラの利用目的（`NSCameraUsageDescription`）は設定済み
- `google_mlkit_pose_detection` の README にある手順が必要です
  - Runner の Other Linker Flags に `-ObjC` と `-all_load` を追加
  - ML Kit のリソースバンドル（`MLKitPoseDetection*Resources.bundle` など）を Runner に追加
- ML Kit の姿勢推定は iOS シミュレーターでは動かないため、実機で確認します

## 構成

- `lib/main.dart` … アプリの起動（縦向き固定）
- `lib/ui/pose_check_screen.dart` … カメラ映像、⭕️ の表示、ボタン
- `lib/ui/skeleton_painter.dart` … 骨格の描画
- `lib/camera/` … カメラのフレームを ML Kit の入力に変換、検出結果の変換
- `lib/pose/judge.dart` … ポーズ定義に沿った判定、表示の安定化
- `lib/pose/metrics.dart` … ランドマークから指標を計算
- `lib/pose/poses/` … ポーズ定義（データ）。ポーズを追加するときはここにファイルを足す
