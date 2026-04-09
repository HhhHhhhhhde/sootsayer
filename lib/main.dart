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
    const surfaceColor = Color(0xFF121821);
    const cardColor = Color(0xFF1A2230);
    const borderColor = Color(0xFFB8C2D9);
    const textPrimary = Color(0xFFF4F7FF);
    const textSecondary = Color(0xFFD5DDF0);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2D5BFF),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: surfaceColor,
      dividerColor: borderColor.withOpacity(0.45),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary),
        titleMedium: TextStyle(color: textPrimary),
        titleSmall: TextStyle(color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE5FF), width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor),
          textStyle: const TextStyle(color: textPrimary),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
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
    const surfaceColor = Color(0xFF1A1315);
    const cardColor = Color(0xFF241B1F);
    const borderColor = Color(0xFFF5C8CE);
    const textPrimary = Color(0xFFFFF3F4);
    const textSecondary = Color(0xFFFFDDE1);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6B6B),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: surfaceColor,
      dividerColor: borderColor.withOpacity(0.45),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary),
        titleMedium: TextStyle(color: textPrimary),
        titleSmall: TextStyle(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor),
          textStyle: const TextStyle(color: textPrimary),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
    );
  }
}
