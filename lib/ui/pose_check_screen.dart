import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:material_ui/material_ui.dart';

import '../camera/input_image_converter.dart';
import '../camera/pose_landmarks.dart';
import '../pose/judge.dart';
import '../pose/pose_definition.dart';
import 'skeleton_painter.dart';

const _green = Color(0xFF22C55E);

/// カメラ映像からポーズを判定して、合っていれば上部に緑の ⭕️ を出す画面
class PoseCheckScreen extends StatefulWidget {
  const PoseCheckScreen({super.key, required this.pose});

  final PoseDefinition pose;

  @override
  State<PoseCheckScreen> createState() => _PoseCheckScreenState();
}

class _PoseCheckScreenState extends State<PoseCheckScreen> with WidgetsBindingObserver {
  final _detector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
  final _stabilizer = Stabilizer();
  final _clock = Stopwatch()..start();

  List<CameraDescription> _cameras = [];
  CameraDescription? _camera;
  CameraController? _controller;
  bool _busy = false;
  String? _error;

  Pose? _pose;
  Size? _imageSize;
  Judgement? _judgement;
  bool _ok = false;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _detector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // バックグラウンドではカメラを止め、戻ったら再開する
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed && _camera != null && _controller == null) {
      _startCamera(_camera!);
    }
  }

  Future<void> _init() async {
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      setState(() => _error = 'カメラを取得できませんでした（${e.code}）');
      return;
    }
    if (_cameras.isEmpty) {
      setState(() => _error = 'カメラが見つかりません');
      return;
    }
    // 自分で確認しやすいよう、前面カメラを優先
    final front = _cameras.where((c) => c.lensDirection == CameraLensDirection.front);
    await _startCamera(front.isNotEmpty ? front.first : _cameras.first);
  }

  Future<void> _startCamera(CameraDescription camera) async {
    _camera = camera;
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      await controller.startImageStream(_onFrame);
      setState(() => _error = null);
    } on CameraException catch (e) {
      final denied = e.code.contains('AccessDenied') || e.code.contains('Permission');
      setState(() => _error = denied
          ? 'カメラの使用を許可してください（設定アプリ → アプリ → カメラ）'
          : 'カメラを起動できませんでした（${e.code}）');
    }
  }

  Future<void> _stopCamera() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;
    if (c.value.isStreamingImages) await c.stopImageStream().catchError((_) {});
    await c.dispose();
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _camera == null) return;
    final next = _cameras[(_cameras.indexOf(_camera!) + 1) % _cameras.length];
    await _stopCamera();
    setState(() {
      _pose = null;
      _judgement = null;
    });
    await _startCamera(next);
  }

  Future<void> _onFrame(CameraImage image) async {
    // 前のフレームの処理中は捨てる
    if (_busy || _camera == null) return;
    _busy = true;
    try {
      final input = inputImageFromCameraImage(image, _camera!);
      if (input == null) return;
      final poses = await _detector.processImage(input);
      if (!mounted) return;
      final pose = poses.firstOrNull;
      final judgement = judgePose(widget.pose, pose == null ? null : toLandmarks(pose));
      final ok = _stabilizer.update(judgement is Judged && judgement.ok, _clock.elapsed);
      setState(() {
        _pose = pose;
        _imageSize = uprightImageSize(input);
        _judgement = judgement;
        _ok = ok;
      });
    } catch (e) {
      debugPrint('pose detection failed: $e');
    } finally {
      _busy = false;
    }
  }

  String get _statusText {
    if (_error != null) return _error!;
    if (_ok) return '${widget.pose.name}のポーズです';
    return switch (_judgement) {
      null => widget.pose.cameraGuide,
      NoPerson j => '${j.message}\n${widget.pose.cameraGuide}',
      LowVisibility j => j.message,
      Judged j => j.message ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final mirror = _camera?.lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            Center(
              child: CameraPreview(
                controller,
                child: _pose != null && _imageSize != null
                    ? CustomPaint(
                        painter: SkeletonPainter(
                          pose: _pose!,
                          imageSize: _imageSize!,
                          mirror: mirror,
                          color: _ok ? _green : Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          _TopBar(ok: _ok, status: _statusText),
          if (_showDetails && _judgement is Judged) _Details(judgement: _judgement as Judged),
          _BottomBar(
            canSwitch: _cameras.length > 1,
            onSwitch: _switchCamera,
            onToggleDetails: () => setState(() => _showDetails = !_showDetails),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.ok, required this.status});
  final bool ok;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x99000000), Color(0x00000000)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 緑の ⭕️（OK のときだけ表示）
                AnimatedScale(
                  scale: ok ? 1 : 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedOpacity(
                    opacity: ok ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Semantics(
                      label: ok ? 'OK' : null,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _green, width: 14),
                          boxShadow: const [BoxShadow(color: Color(0xCC22C55E), blurRadius: 24)],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.judgement});
  final Judged judgement;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 96,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xA6000000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            [
              for (final c in judgement.checks)
                '${c.ok ? '○' : '×'} ${c.check.label}: ${c.value?.toStringAsFixed(2) ?? '—'}',
            ].join('\n'),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.canSwitch, required this.onSwitch, required this.onToggleDetails});
  final bool canSwitch;
  final VoidCallback onSwitch;
  final VoidCallback onToggleDetails;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: const Color(0x80000000),
      side: const BorderSide(color: Color(0x80FFFFFF)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      textStyle: const TextStyle(fontSize: 16),
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (canSwitch) OutlinedButton(style: style, onPressed: onSwitch, child: const Text('カメラ切替')),
              const SizedBox(width: 12),
              OutlinedButton(style: style, onPressed: onToggleDetails, child: const Text('詳細')),
            ],
          ),
        ),
      ),
    );
  }
}
