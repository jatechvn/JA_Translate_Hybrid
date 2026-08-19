// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

import 'modules/modules.dart';
import 'modules/ui/main_window.dart';
import 'modules/ui/styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo window_manager
  await windowManager.ensureInitialized();

  // Khởi tạo flutter_acrylic để tạo hiệu ứng Mica/Acrylic trên Windows/macOS
  try {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await flutter_acrylic.Window.initialize();
    }
  } catch (e) {
    print('Failed to initialize flutter_acrylic: $e');
  }

  // Cấu hình kích thước và thuộc tính cửa sổ ứng dụng
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750),
    minimumSize: Size(950, 650),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal, // Giữ titlebar hệ thống và đồng bộ qua MethodChannel
    title: appName,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Khởi tạo hệ thống ghi log
  await initLogger();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TranslationLogic()),
        ChangeNotifierProxyProvider<TranslationLogic, ThemeProvider>(
          create: (_) => ThemeProvider(),
          update: (_, logic, themeProvider) {
            // Đồng bộ cài đặt từ config của logic sang themeProvider
            if (themeProvider != null && logic.isInitialized) {
              final isDark = logic.config.themeMode == 'dark';
              final mode = isDark ? ThemeMode.dark : ThemeMode.light;
              final transparency = logic.config.enableTransparency;
              
              if (themeProvider.themeMode != mode || themeProvider.enableTransparency != transparency) {
                // Sử dụng addPostFrameCallback để tránh gọi notifyListeners trong lúc build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  themeProvider.updateTheme(mode, transparency);
                });
              }
            }
            return themeProvider ?? ThemeProvider();
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: appName,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: const MainWindow(),
          );
        },
      ),
    );
  }
}
