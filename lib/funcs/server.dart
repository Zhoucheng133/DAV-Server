import 'package:dav_server/funcs/dialogs.dart';
import 'package:dav_server/variables/main_var.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Server {

  final MainVar m=Get.find();

  void run(BuildContext context, String username, String password, String port, String path){
    if(path.isEmpty){
      showErr(context, "启动服务失败", "分享路径不能为空");
      return;
    }
  }

  void stop(){

  }
}