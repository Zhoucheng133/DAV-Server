import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:dav_server/controllers/controller.dart';
import 'package:dav_server/funcs/dialogs.dart';
import 'package:dav_server/funcs/server.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {

  final server=Server();

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if(controller.running.value){
        showDialog(
          // ignore: use_build_context_synchronously
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: Text('serviceRunning'.tr),
            content: Text('youNeedToStop'.tr),
            actions: [
              FilledButton(
                onPressed: ()=>Navigator.pop(context), 
                child: Text('ok'.tr)
              )
            ],
          )
        );
      }else{
        await windowManager.setPreventClose(false);
        await windowManager.close();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  final controller=Get.find<Controller>();

  Future<void> auth(BuildContext context) async {
    await showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (context)=>AlertDialog(
        title: Text('auth'.tr),
        titlePadding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 0),
        contentPadding: const EdgeInsets.only(left: 24, right: 24, top: 5, bottom: 0),
        actionsPadding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
        content: Obx(
          ()=> Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(-10, 0),
                child: Row(
                  children: [
                    Checkbox(
                      splashRadius: 0,
                      value: controller.anonymous.value, 
                      onChanged: (val){
                        setState(() {
                          controller.anonymous.value=val!;
                        });
                      }
                    ),
                    GestureDetector(
                      onTap: (){
                        setState(() {
                          controller.anonymous.value=!controller.anonymous.value;
                        });
                      },
                      child: Text('anonymousAccess'.tr)
                    )
                  ],
                ),
              ),
              if(!controller.anonymous.value) const SizedBox(height: 5,),
              if(!controller.anonymous.value) TextField(
                controller: controller.username,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal[100]!, width: 1.0),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  isCollapsed: true,
                  labelText: "username".tr,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  hintStyle: TextStyle(
                    color: Colors.grey[400]
                  )
                ),
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              if(!controller.anonymous.value) const SizedBox(height: 15,),
              if(!controller.anonymous.value) TextField(
                controller: controller.password,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal[100]!, width: 1.0),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  labelText: "password".tr,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  hintStyle: TextStyle(
                    color: Colors.grey[400]
                  )
                ),
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: (){
              if(!controller.anonymous.value && (controller.username.text.isEmpty || controller.password.text.isEmpty)){
                showErr(context, "setFailed".tr, "usernamePasswordEmpty".tr);
                return;
              }
              Navigator.pop(context);
            }, 
            child: Text('ok'.tr)
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 30,
          color: Colors.transparent,
          child: Platform.isWindows ? Row(
            children: [
              Expanded(child: DragToMoveArea(child: Container())),
              WindowCaptionButton.minimize(onPressed: ()=>windowManager.minimize(),),
              WindowCaptionButton.close(onPressed: ()=>windowManager.close(),)
            ],
          ) : DragToMoveArea(child: Container())
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Obx(
              ()=> Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('sharePath'.tr)
                  ),
                  const SizedBox(height: 5,),
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: controller.sharePath.text,
                          child: TextField(
                            controller: controller.sharePath,
                            enabled: false,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)
                              ),
                              hintText: 'sharePath'.tr,
                              isCollapsed: true,
                              contentPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10)
                            ),
                            autocorrect: false,
                            enableSuggestions: false,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10,),
                      FilledButton(
                        onPressed: controller.running.value ? null : () async {
                          String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                          if(selectedDirectory!=null){
                            setState(() {
                              controller.sharePath.text=selectedDirectory;
                            });
                          }
                        }, 
                        child: Text('select'.tr)
                      )
                    ],
                  ),
                  const SizedBox(height: 15,),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('port'.tr)
                  ),
                  const SizedBox(height: 5,),
                  TextField(
                    enabled: !controller.running.value,
                    controller: controller.sharePort,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal[100]!, width: 1.0),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10)
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 15,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: controller.running.value ? null : ()=>auth(context), 
                        child: Text('authSetting'.tr)
                      ),
                      const SizedBox(width: 10,),
                      if(controller.anonymous.value) Tooltip(
                        message: 'anonymousAccess'.tr,
                        child: Icon(Icons.info_outline_rounded, size: 20,),
                      ),
                      Expanded(child: Container()),
                      PopupMenuButton<LanguageType>(
                        borderRadius: BorderRadius.circular(18),
                        tooltip: 'language'.tr,
                        icon: Icon(Icons.translate_rounded),
                        iconSize: 20,
                        itemBuilder: (context)=>supportedLocales.map((e) {
                          return PopupMenuItem<LanguageType>(
                            value: e,
                            child: Text(e.name),
                          );
                        }).toList(),
                        onSelected: (LanguageType value){
                          int index=supportedLocales.indexWhere((element) => element.locale==value.locale);
                          controller.changeLanguage(index);
                        },
                      )
                    ],
                  ),
                  Expanded(child: Container()),
                  Row(
                    children: [
                      const Icon(
                        Icons.podcasts_rounded,
                      ),
                      const SizedBox(width: 5,),
                      Tooltip(
                        message: "clickToCopy".tr,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: (){
                              FlutterClipboard.copy("${controller.address.value}:${controller.sharePort.text}");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("copyed".tr),
                                  duration: Duration(milliseconds: 500),
                                ),
                              );
                            },
                            child: ValueListenableBuilder(
                              valueListenable: controller.sharePort, 
                              builder: (context, value, child)=>Text("${controller.address.value}:${value.text}")
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Container()),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          mouseCursor: SystemMouseCursors.basic,
                          splashRadius: 0,
                          value: controller.running.value, 
                          onChanged: (val) async {
                            if(controller.running.value){
                              server.stop();
                              controller.running.value=false;
                            }else{
                              if(await server.checkRun(context, controller.sharePort.text, controller.sharePath.text)){
                                controller.running.value=true;
                                server.run(!controller.anonymous.value ? controller.username.text : "", !controller.anonymous.value ? controller.password.text : "", controller.sharePort.text, controller.sharePath.text);
                              }
                            }
                          }
                        ),
                      )
                    ]
                  ),
                  SizedBox(height: 20,),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}