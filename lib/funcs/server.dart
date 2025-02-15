import 'dart:io';

import 'package:dav_server/funcs/dialogs.dart';
import 'package:dav_server/variables/main_var.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Server {

  final MainVar m=Get.put(MainVar());
  late String corePath;
  late Shell shell;
  late final SharedPreferences prefs;

  Future<void> init() async {
    prefs=await SharedPreferences.getInstance();
    String supportDir=(await getApplicationSupportDirectory()).path;
    corePath=p.join(supportDir, Platform.isWindows ? "core.exe" : "core");
    final file = File(corePath);
    if(!file.existsSync()){
      final ByteData data = await rootBundle.load(Platform.isWindows ? "assets/core.exe" : "assets/core");
      final buffer = data.buffer.asUint8List();
      await file.writeAsBytes(buffer);
    }
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', corePath]);
    }
    shell=Shell();
  }

  Server(){
    init();
  }

  Future<bool> checkRun(BuildContext context, String port, String path) async {
    if(path.isEmpty){
      showErr(context, "启动服务失败", "分享路径不能为空");
      return false;
    }
    try {
      int intport=int.parse(port);
      if(intport<=1000 || intport>=100000){
        showErr(context, "启动服务失败", "端口号不合法");
        return false;
      }
    } catch (_) {
      return false;
    }
    if(await portCheck(port)){
      return true;
    }
    if(context.mounted){
      showErr(context, "启动服务失败", "端口号被占用");
    }
    return false;
  }

  String getCmd(String port, String path, String username, String password){
    String cmd="'$corePath' -port $port -path '$path'";
    if(username.isNotEmpty && password.isNotEmpty){
      cmd+=" -u $username -p $password";
    }
    return cmd;
  }

  Future<bool> portCheck(String port) async {
    try {
      int portConvert=int.parse(port);
      final server = await ServerSocket.bind("0.0.0.0", portConvert);
      await server.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> run(String username, String password, String port, String path) async {
     try {
      prefs.setString("port", port);
      prefs.setString("username", username);
      prefs.setString("password", password);
      prefs.setString("path", path);
      final cmd=getCmd(port, path, username, password);
      print(cmd);
      await shell.run(cmd);
    } on ShellException catch (_) {}
  }

  void stop(){
    try {
      shell.kill();
    } catch (_) {}
  }
}