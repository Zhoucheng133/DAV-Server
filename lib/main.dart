import 'package:dav_server/lang/en_us.dart';
import 'package:dav_server/lang/zh_cn.dart';
import 'package:dav_server/lang/zh_tw.dart';
import 'package:dav_server/main_window.dart';
import 'package:dav_server/controllers/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 330),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: "DAV Server"
  );
  final controller=Get.put(Controller());
  await controller.init();
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setResizable(false);
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MainApp());
}

class MainTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'zh_CN': zhCN,
    'zh_TW': zhTW,
  };
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  final Controller controller=Get.find();

  @override
  Widget build(BuildContext context) {

    final brightness = MediaQuery.of(context).platformBrightness;

    return Obx(()=>
      GetMaterialApp(
        debugShowCheckedModeBanner: false,
        locale: controller.lang.value.locale,
        translations: MainTranslations(),
        fallbackLocale: const Locale('en', 'US'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: supportedLocales.map((item)=>item.locale).toList(),
        theme: brightness==Brightness.dark ? ThemeData.dark().copyWith(
          textTheme: GoogleFonts.notoSansScTextTheme().apply(
            bodyColor: Colors.white,
            displayColor: Colors.white, 
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
        ) : ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          textTheme: GoogleFonts.notoSansScTextTheme(),
        ),
        home: const Scaffold(
          body: MainWindow()
        ),
      )
    );
  }
}
