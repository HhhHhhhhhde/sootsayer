import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/analysis_provider.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // AnalysisProvider watches AuthProvider: fetches tasks & starts
        // polling automatically when the user logs in.
        ChangeNotifierProxyProvider<AuthProvider, AnalysisProvider>(
          create: (_) => AnalysisProvider(),
          update: (_, auth, analysis) {
            final provider = analysis ?? AnalysisProvider();
            if (auth.isLoggedIn && auth.sessionToken != null) {
              provider.setToken(auth.sessionToken!);
            } else {
              provider.clearToken();
            }
            return provider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        // 如果主题还没有初始化，显示加载屏幕
        if (!themeProvider.isInitialized) {
          return MaterialApp(
            title: 'FlowDroid Security',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        late ThemeData lightTheme;
        late ThemeData darkTheme;

        switch (themeProvider.appTheme) {
          case AppTheme.light:
            lightTheme = _buildLightTheme();
            darkTheme = _buildDarkTheme();
            break;
          case AppTheme.dark:
            lightTheme = _buildDarkTheme();
            darkTheme = _buildDarkTheme();
            break;
          case AppTheme.highSaturation:
            lightTheme = _buildHighSaturationTheme();
            darkTheme = _buildHighSaturationDarkTheme();
            break;
        }

        return MaterialApp(
          title: 'FlowDroid Security',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: authProvider.isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
        );
      },
    );
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2D5BFF),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2D5BFF),
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2D2D2D)),
        ),
      ),
    );
  }

  static ThemeData _buildHighSaturationTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6B6B),
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData _buildHighSaturationDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6B6B),
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2D2D2D)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
    );
  }
}
