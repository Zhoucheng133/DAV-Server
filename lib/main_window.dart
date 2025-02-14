import 'dart:io';

import 'package:dav_server/funcs/dialogs.dart';
import 'package:dav_server/variables/main_var.dart';
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
  String address="";

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
    setState(() {
      sharePort.text=port??"8080";
    });
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
                  useAuth=false;
                }else{
                  useAuth=true;
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
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Column(
            children: [
              const SizedBox(height: 15,),
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
                  Obx(()=>
                    FilledButton(
                      onPressed: m.running.value ? null : ()=>auth(context), 
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
                  Text("$address:${sharePort.text}"),
                  Expanded(child: Container()),
                  Obx(()=>
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        splashRadius: 0,
                        value: m.running.value, 
                        onChanged: (val) async {
                          // TODO 运行
                        }
                      ),
                    )
                  )
                ]
              )
            ],
          ),
        ),
      ],
    );
  }
}