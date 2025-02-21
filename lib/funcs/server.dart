import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:dav_server/funcs/dialogs.dart';
import 'package:dav_server/variables/main_var.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';


typedef StartServer = void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef StartServerFunc = Void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

typedef StopServer=int Function();
typedef StopServerFunc=Int32 Function();

class Server {

  final MainVar m=Get.put(MainVar());
  late String corePath;
  late final SharedPreferences prefs;

  late DynamicLibrary dynamicLib;
  late StopServer stopServer;

  Future<void> init() async {
    prefs=await SharedPreferences.getInstance();

    dynamicLib=DynamicLibrary.open(Platform.isMacOS ? 'server.dylib' : 'server.dll');

    stopServer=dynamicLib
    .lookup<NativeFunction<StopServerFunc>>('StopServer')
    .asFunction();

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

  late Isolate isolate;

  static void isolateFunction(List<String> params){
    final dynamicLib = DynamicLibrary.open(Platform.isMacOS ? 'server.dylib' : 'server.dll');
    StartServer startServer=dynamicLib
    .lookup<NativeFunction<StartServerFunc>>('StartServer')
    .asFunction();

    startServer(params[0].toNativeUtf8(), params[1].toNativeUtf8(), params[2].toNativeUtf8(), params[3].toNativeUtf8());
  }

  Future<void> run(String username, String password, String port, String path) async {
    prefs.setString("port", port);
    prefs.setString("username", username);
    prefs.setString("password", password);
    prefs.setString("path", path);
    isolate=await Isolate.spawn(isolateFunction, [port, path, username, password]);
  }

  Future<void> stop() async {
    stopServer();
    isolate.kill();
  }
}