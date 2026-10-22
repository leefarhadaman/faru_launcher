import 'package:flutter/material.dart';

import '../launcher/home_screen.dart';
import '../launcher/launcher_controller.dart';
import 'theme.dart';

class FaruLauncherApp extends StatelessWidget {
  const FaruLauncherApp({super.key, this.controller});

  final LauncherController? controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auvriko',
      debugShowCheckedModeBanner: false,
      theme: FaruTheme.darkTheme,
      home: HomeScreen(controller: controller),
    );
  }
}
