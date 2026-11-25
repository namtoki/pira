import 'metrics.dart';
import 'pose_definition.dart';

class CheckResult {
  const CheckResult({required this.check, required this.value, required this.ok, this.message});
  final PoseCheck check;

  /// 指標の値。部位が見えず判定を省略したときは null
  final double? value;
  final bool ok;
  final String? message;
}

sealed class Judgement {
  const Judgement();
}

class NoPerson extends Judgement {
  const NoPerson();
  String get message => '人が映っていません';
}

class LowVisibility extends Judgement {
  const LowVisibility();
  String get message => '全身が映るようにしてください';
}

class Judged extends Judgement {
  const Judged(this.checks);
  final List<CheckResult> checks;
  bool get ok => checks.every((c) => c.ok);
  String? get message => checks.where((c) => !c.ok).firstOrNull?.message;
}

/// 1 フレーム分の判定。[landmarks] が null なら人が見つからなかった。
Judgement judgePose(PoseDefinition pose, Map<Landmark, Point>? landmarks) {
  if (landmarks == null || landmarks.isEmpty) return const NoPerson();
  final visible = pose.requiredLandmarks
      .every((id) => (landmarks[id]?.likelihood ?? 0) >= pose.minLikelihood);
  if (!visible) return const LowVisibility();

  final metrics = computeMetrics(landmarks);
  return Judged([
    for (final c in pose.checks) _evaluate(c, metrics[c.metric]),
  ]);
}

CheckResult _evaluate(PoseCheck c, double? value) {
  if (value == null) return CheckResult(check: c, value: null, ok: true);
  if (c.min != null && value < c.min!) {
    return CheckResult(check: c, value: value, ok: false, message: c.tooLow);
  }
  if (c.max != null && value > c.max!) {
    return CheckResult(check: c, value: value, ok: false, message: c.tooHigh);
  }
  return CheckResult(check: c, value: value, ok: true);
}

/// 判定のチラつきを抑える。OK/NG が [hold] の間続いたときだけ表示を切り替える。
class Stabilizer {
  Stabilizer({this.hold = const Duration(milliseconds: 400)});

  final Duration hold;
  bool _shown = false;
  bool _candidate = false;
  Duration _since = Duration.zero;

  bool update(bool ok, Duration now) {
    if (ok != _candidate) {
      _candidate = ok;
      _since = now;
    }
    if (_candidate != _shown && now - _since >= hold) _shown = _candidate;
    return _shown;
  }
}
