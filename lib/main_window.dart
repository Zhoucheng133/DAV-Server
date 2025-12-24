import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:dav_server/controllers/controller.dart';
import 'package:dav_server/funcs/dialogs.dart';
import 'package:dav_server/funcs/server.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {

  late final SharedPreferences prefs;
  final server=Server();
  String address="";

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

  Future<void> getAddress() async {
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      final addresses = interface.addresses;
      final localAddresses = addresses.where((address) => !address.isLoopback && address.type.name=="IPv4");
      for (final localAddress in localAddresses) {
        setState(() {
          address=localAddress.address;
        });
        return;
      }
    }
  }

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    String? port=prefs.getString("port");
    String? path=prefs.getString("path");
    String? u=prefs.getString("username");
    String? p=prefs.getString("password");
    setState(() {
      sharePort.text=port??"8080";
      sharePath.text=path??"";
    });
    if(u!=null && p!=null && u.isNotEmpty && p.isNotEmpty){
      setState(() {
        useAuth=true;
        username.text=u;
        password.text=p;
      });
    }
    await windowManager.setPreventClose(true);
  }

  @override
  void initState() {
    super.initState();
    getAddress();
    init();
    windowManager.setResizable(false);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  TextEditingController sharePath=TextEditingController();
  TextEditingController sharePort=TextEditingController();

  final controller=Get.find<Controller>();
  
  bool useAuth=false;
  TextEditingController username=TextEditingController();
  TextEditingController password=TextEditingController();

  void auth(BuildContext context){
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (context)=>AlertDialog(
        title: Text('authSetting'.tr),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: username,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal[100]!, width: 1.0),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    hintText: 'allowAnonymous'.tr,
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
                const SizedBox(height: 15,),
                TextField(
                  controller: password,
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
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: (){
              setState(() {
                useAuth=false;
                username.text="";
                password.text="";
              });
              Navigator.pop(context);
            }, 
            child: Text("cancel".tr)
          ),
          FilledButton(
            onPressed: (){
              if((username.text.isEmpty && password.text.isNotEmpty) || (username.text.isNotEmpty && password.text.isEmpty)){
                showErr(context, "setFailed".tr, "usernamePasswordBoth".tr);
                return;
              }else{
                if(username.text.isEmpty && password.text.isEmpty){
                  setState(() {
                    useAuth=false;
                  });
                }else{
                  setState(() {
                    useAuth=true;
                  });
                }
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
            child: Column(
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
                        message: sharePath.text,
                        child: TextField(
                          controller: sharePath,
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
                    Obx(()=>
                      FilledButton(
                        onPressed: controller.running.value ? null : () async {
                          String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                          if(selectedDirectory!=null){
                            setState(() {
                              sharePath.text=selectedDirectory;
                            });
                          }
                        }, 
                        child: Text('select'.tr)
                      )
                    )
                  ],
                ),
                const SizedBox(height: 15,),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('port'.tr)
                ),
                const SizedBox(height: 5,),
                Row(
                  children: [
                    Expanded(
                      child: Obx(()=>
                        TextField(
                          enabled: !controller.running.value,
                          controller: sharePort,
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
                      )
                    ),
                    const SizedBox(width: 10,),
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
                const SizedBox(height: 15,),
                Row(
                  children: [
                    Expanded(
                      child: Obx(()=>
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              splashRadius: 0,
                              value: useAuth, 
                              onChanged: controller.running.value ? null : (val){
                                if(val!=null){
                                  setState(() {
                                    useAuth=val;
                                  });
                                }
                                if(val==true){
                                  auth(context);
                                }
                              }
                            ),
                            GestureDetector(
                              onTap: (){
                                if(controller.running.value){
                                  return;
                                }
                                setState(() {
                                  useAuth=!useAuth;
                                });
                                if(useAuth){
                                  auth(context);
                                }
                              },
                              child: MouseRegion(
                                cursor: controller.running.value ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                                child: Text(
                                  'useAuth'.tr,
                                  style: TextStyle(
                                    color: controller.running.value ? Colors.grey[400] : Colors.black
                                  ),
                                )
                              )
                            )
                          ],
                        ),
                      )
                    ),
                    Obx(()=>
                      FilledButton(
                        onPressed: controller.running.value ? null : useAuth ? ()=>auth(context) : null, 
                        child: Text('authSetting'.tr)
                      )
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
                            FlutterClipboard.copy("$address:${sharePort.text}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("copyed".tr),
                                duration: Duration(milliseconds: 500),
                              ),
                            );
                          },
                          child: ValueListenableBuilder(
                            valueListenable: sharePort, 
                            builder: (context, value, child)=>Text("$address:${value.text}")
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: Container()),
                    Obx(()=>
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          splashRadius: 0,
                          value: controller.running.value, 
                          onChanged: (val) async {
                            if(controller.running.value){
                              server.stop();
                              controller.running.value=false;
                            }else{
                              if(await server.checkRun(context, sharePort.text, sharePath.text)){
                                controller.running.value=true;
                                server.run(useAuth ? username.text : "", useAuth ? password.text : "", sharePort.text, sharePath.text);
                              }
                            }
                          }
                        ),
                      )
                    )
                  ]
                ),
                SizedBox(height: 20,),
              ],
            ),
          ),
        ),
      ],
    );
  }
}