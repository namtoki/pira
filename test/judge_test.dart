import 'package:flutter_test/flutter_test.dart';
import 'package:pira/pose/judge.dart';
import 'package:pira/pose/pose_definition.dart';
import 'package:pira/pose/poses/zazen.dart';

typedef Pts = Map<Landmark, Point>;

Pts make(Map<Landmark, (double, double)> m) =>
    {for (final e in m.entries) e.key: Point(e.value.$1, e.value.$2, 0.95)};

// 正面から見た座禅（胴の長さ 300px）
final zazenPose = make({
  Landmark.nose: (500, 250),
  Landmark.leftShoulder: (430, 350), Landmark.rightShoulder: (570, 350),
  Landmark.leftWrist: (480, 680), Landmark.rightWrist: (520, 680),
  Landmark.leftHip: (460, 650), Landmark.rightHip: (540, 650),
  Landmark.leftKnee: (320, 700), Landmark.rightKnee: (680, 700),
  Landmark.leftAnkle: (450, 720), Landmark.rightAnkle: (550, 720),
});

final standing = make({
  Landmark.nose: (500, 150),
  Landmark.leftShoulder: (430, 250), Landmark.rightShoulder: (570, 250),
  Landmark.leftWrist: (400, 550), Landmark.rightWrist: (600, 550),
  Landmark.leftHip: (460, 550), Landmark.rightHip: (540, 550),
  Landmark.leftKnee: (460, 750), Landmark.rightKnee: (540, 750),
  Landmark.leftAnkle: (460, 950), Landmark.rightAnkle: (540, 950),
});

// 椅子に座っている（正面）: ひざは腰と同じ高さに見えるが、足首は下
final chair = make({
  Landmark.nose: (500, 150),
  Landmark.leftShoulder: (430, 250), Landmark.rightShoulder: (570, 250),
  Landmark.leftWrist: (470, 560), Landmark.rightWrist: (530, 560),
  Landmark.leftHip: (460, 550), Landmark.rightHip: (540, 550),
  Landmark.leftKnee: (380, 600), Landmark.rightKnee: (620, 600),
  Landmark.leftAnkle: (380, 900), Landmark.rightAnkle: (620, 900),
});

Pts withPoint(Pts base, Landmark id, Point p) => {...base, id: p};

void main() {
  test('座禅のポーズは OK', () {
    final j = judgePose(zazen, zazenPose);
    expect(j, isA<Judged>());
    expect((j as Judged).ok, isTrue);
  });

  test('立っているときは NG', () {
    expect((judgePose(zazen, standing) as Judged).ok, isFalse);
  });

  test('椅子に座っているときは NG', () {
    expect((judgePose(zazen, chair) as Judged).ok, isFalse);
  });

  test('手を上げていると NG で、手の位置を指摘する', () {
    var p = withPoint(zazenPose, Landmark.leftWrist, const Point(480, 300, 0.95));
    p = withPoint(p, Landmark.rightWrist, const Point(520, 300, 0.95));
    final j = judgePose(zazen, p) as Judged;
    expect(j.ok, isFalse);
    expect(j.message, '手はおなかの前、足の上で組んでください');
  });

  test('足首が見えなくても、ほかが合っていれば OK', () {
    var p = withPoint(zazenPose, Landmark.leftAnkle, const Point(450, 720, 0.05));
    p = withPoint(p, Landmark.rightAnkle, const Point(550, 720, 0.05));
    expect((judgePose(zazen, p) as Judged).ok, isTrue);
  });

  test('ひざが見えないときは判定しない', () {
    final p = withPoint(zazenPose, Landmark.leftKnee, const Point(320, 700, 0.1));
    expect(judgePose(zazen, p), isA<LowVisibility>());
  });

  test('人がいないとき', () {
    expect(judgePose(zazen, null), isA<NoPerson>());
  });

  test('Stabilizer は一定時間続いたときだけ切り替える', () {
    final s = Stabilizer(hold: const Duration(milliseconds: 400));
    expect(s.update(true, Duration.zero), isFalse);
    expect(s.update(true, const Duration(milliseconds: 300)), isFalse);
    expect(s.update(true, const Duration(milliseconds: 400)), isTrue);
    expect(s.update(false, const Duration(milliseconds: 500)), isTrue);
    expect(s.update(true, const Duration(milliseconds: 600)), isTrue);
    expect(s.update(false, const Duration(milliseconds: 700)), isTrue);
    expect(s.update(false, const Duration(milliseconds: 1100)), isFalse);
  });
}
