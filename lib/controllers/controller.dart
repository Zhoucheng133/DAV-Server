import 'dart:ui';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageType{
  String name;
  Locale locale;

  LanguageType(this.name, this.locale);
}

List<LanguageType> get supportedLocales => [
  LanguageType("English", Locale("en", "US")),
  LanguageType("简体中文", Locale("zh", "CN")),
  LanguageType("繁體中文", Locale("zh", "TW")),
];

class Controller extends GetxController {
  RxBool running=false.obs;

  Rx<LanguageType> lang=Rx(supportedLocales[0]);

  late SharedPreferences prefs;

  Future<void> init() async {
    prefs=await SharedPreferences.getInstance();

    int? langIndex=prefs.getInt("langIndex");

    if(langIndex==null){
      final deviceLocale=PlatformDispatcher.instance.locale;
      final local=Locale(deviceLocale.languageCode, deviceLocale.countryCode);
      int index=supportedLocales.indexWhere((element) => element.locale==local);
      if(index!=-1){
        lang.value=supportedLocales[index];
        lang.refresh();
      }
    }else{
      lang.value=supportedLocales[langIndex];
    }
  }

  void changeLanguage(int index){
    lang.value=supportedLocales[index];
    prefs.setInt("langIndex", index);
    lang.refresh();
    Get.updateLocale(lang.value.locale);
  }
}