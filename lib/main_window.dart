import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:dav_server/funcs/dialogs.dart';
import 'package:dav_server/funcs/server.dart';
import 'package:dav_server/variables/main_var.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String version="";

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if(m.running.value){
        showDialog(
          // ignore: use_build_context_synchronously
          context: context, 
          builder: (BuildContext context)=>AlertDialog(
            title: const Text('服务在运行中'),
            content: const Text('你需要先关闭服务才能退出'),
            actions: [
              FilledButton(
                onPressed: ()=>Navigator.pop(context), 
                child: const Text('好的')
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
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version="v${packageInfo.version}";
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
  final m=Get.put(MainVar());
  
  bool useAuth=false;
  TextEditingController username=TextEditingController();
  TextEditingController password=TextEditingController();

  void auth(BuildContext context){
    showDialog(
      context: context, 
      builder: (context)=>AlertDialog(
        title: const Text('用户设置'),
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
                    hintText: '如果允许匿名访问则留空',
                    isCollapsed: true,
                    labelText: "用户名",
                    contentPadding: const EdgeInsets.only(top: 15, bottom: 10, left: 10, right: 10),
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
                    labelText: "密码",
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(top: 15, bottom: 10, left: 10, right: 10),
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
          FilledButton(
            onPressed: (){
              
              if((username.text.isEmpty && password.text.isNotEmpty) || (username.text.isNotEmpty && password.text.isEmpty)){
                showErr(context, "设置失败", "用户名和密码必须都要填写或都不填写");
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
            child: const Text('完成')
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
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('分享路径')
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
                          hintText: '选择分享路径',
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
                      onPressed: m.running.value ? null : () async {
                        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                        if(selectedDirectory!=null){
                          setState(() {
                            sharePath.text=selectedDirectory;
                          });
                        }
                      }, 
                      child: const Text('选择')
                    )
                  )
                ],
              ),
              const SizedBox(height: 15,),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('端口号')
              ),
              const SizedBox(height: 5,),
              Row(
                children: [
                  Expanded(
                    child: Obx(()=>
                      TextField(
                        enabled: !m.running.value,
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
                ],
              ),
              const SizedBox(height: 15,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Obx(()=>
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            splashRadius: 0,
                            value: useAuth, 
                            onChanged: m.running.value ? null : (val){
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
                          const SizedBox(width: 5,),
                          GestureDetector(
                            onTap: (){
                              if(m.running.value){
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
                              cursor: m.running.value ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                              child: Text(
                                '启用登录访问',
                                style: TextStyle(
                                  color: m.running.value ? Colors.grey[400] : Colors.black
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
                      onPressed: m.running.value ? null : useAuth ? ()=>auth(context) : null, 
                      child: const Text('用户设置')
                    )
                  )
                ],
              ),
              const SizedBox(height: 30,),
              Row(
                children: [
                  const Icon(
                    Icons.podcasts_rounded,
                  ),
                  const SizedBox(width: 5,),
                  Tooltip(
                    message: "点击复制地址",
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: (){
                          FlutterClipboard.copy("$address:${sharePort.text}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("已复制"),
                              duration: Duration(milliseconds: 500), // 设置显示 1 秒
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
                        value: m.running.value, 
                        onChanged: (val) async {
                          if(m.running.value){
                            server.stop();
                            m.running.value=false;
                          }else{
                            if(await server.checkRun(context, sharePort.text, sharePath.text)){
                              m.running.value=true;
                              server.run(useAuth ? username.text : "", useAuth ? password.text : "", sharePort.text, sharePath.text);
                            }
                          }
                        }
                      ),
                    )
                  )
                ]
              ),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Image.asset("assets/icon.png")
                  ),
                  const SizedBox(width: 5,),
                  GestureDetector(
                    onTap: (){
                      
                    },
                    child: Text(
                      version,
                      style: GoogleFonts.notoSansSc(
                        fontSize: 13,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}