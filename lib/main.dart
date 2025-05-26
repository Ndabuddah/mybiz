import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider()), ChangeNotifierProvider(create: (_) => AuthProvider()), ChangeNotifierProvider(create: (_) => BusinessProvider()), ChangeNotifierProvider(create: (_) => SubscriptionProvider())],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MyBiz',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppColors.primaryColor,
              fontFamily: 'Inter',
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
              colorScheme: ColorScheme.light(primary: AppColors.primaryColor, secondary: AppColors.accentColor),
            ),
            darkTheme: ThemeData(
              primaryColor: AppColors.primaryColor,
              fontFamily: 'Inter',
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.darkBackground,
              appBarTheme: AppBarTheme(backgroundColor: AppColors.darkBackground, foregroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Colors.white)),
              colorScheme: ColorScheme.dark(primary: AppColors.primaryColor, secondary: AppColors.accentColor, surface: AppColors.darkCard, background: AppColors.darkBackground),
            ),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
