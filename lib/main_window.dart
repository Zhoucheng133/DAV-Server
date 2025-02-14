import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {

  @override
  void initState() {
    super.initState();
    windowManager.setResizable(false);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: DragToMoveArea(child: Container())),
            Platform.isWindows? Row(
              children: [
                WindowCaptionButton.minimize(
                  onPressed: ()=>windowManager.minimize()
                ),
                WindowCaptionButton.close(
                  onPressed: ()=>windowManager.close(),
                )
              ],
            ) : Container()
          ],
        ),
        
      ],
    );
  }
}