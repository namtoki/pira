import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'pose/poses/zazen.dart';
import 'ui/pose_check_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 画像の回転計算を簡単にするため縦向きに固定
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PiraApp());
}

class PiraApp extends StatelessWidget {
  const PiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '座禅チェック',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF22C55E), brightness: Brightness.dark),
      home: const PoseCheckScreen(pose: zazen),
    );
  }
}
