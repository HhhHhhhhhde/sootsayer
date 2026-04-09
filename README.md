# SootSayer（Flutter 前端）

SootSayer 是一个基于 Flutter 的 Android 客户端，用于 **提取/选择 APK** 并提交到后端进行隐私风险检测（FlowDroid 静态分析 + AI 解读），以任务的形式展示进度与结果，并提供充值/订阅等账户能力。

## 功能概览

- **APK 提交**：从已安装应用提取 APK 或选择本地文件上传
- **批量提交**：一次提交多个 APK，生成多条任务并统一管理
- **任务历史**：查看所有任务状态（SCANNING / AI_AUDITING / COMPLETED / FAILED 等）
- **报告详情**：风险等级、漏洞/泄露条目与证据链展示（路径节点等）
- **账户体系**：注册/登录、修改密码、忘记密码、账户注销
- **付费与权益**：充值、套餐订阅、余额/账单记录等页面入口
- **体验与设置**：主题切换、通用设置页

## 技术栈

- **Flutter**：3.x
- **状态管理**：Provider（`AuthProvider` / `AnalysisProvider` / `ThemeProvider`）
- **网络请求**：封装在 `lib/services/api_service.dart`
- **本地能力**：APK 提取通过 Android 原生通道（见 `android/app/src/main/java/.../MainActivity.java`）

## 目录结构（关键文件）

```
lib/
  main.dart
  models/
    analysis_result.dart
  providers/
    analysis_provider.dart
    auth_provider.dart
    theme_provider.dart
  services/
    api_service.dart
    apk_service.dart
  screens/
    home_screen.dart
    dashboard_screen.dart
    app_submit_screen.dart
    history_screen.dart
    analysis_detail_screen.dart
    login_screen.dart
    register_screen.dart
    reset_password_screen.dart
    change_password_screen.dart
    delete_account_screen.dart
    profile_screen.dart
    subscription_screen.dart
    recharge_screen.dart
    balance_records_screen.dart
    payment_page_screen.dart
    settings_screen.dart
    theme_settings_screen.dart
  widgets/
    app_submit_card.dart
    recent_analysis_card.dart
    ai_analysis_card.dart
    privacy_tip_card.dart
    privacy_weather_card.dart
```

## 环境要求

- Flutter SDK（建议使用项目已验证的 3.x 版本）
- Android Studio / VS Code
- Android 真机或模拟器

> 需要注意：APK 提取功能依赖 Android 权限与系统限制，建议使用真机测试。

## 快速开始

安装依赖：

```bash
flutter pub get
```

运行（Debug）：

```bash
flutter run
```

构建（Release APK）：

```bash
flutter build apk --release
```

## 配置说明

### 后端地址

前端请求后端 API 的入口在 `lib/services/api_service.dart`。如需切换环境（本地/测试/生产），建议将 baseUrl 抽为常量或使用编译变量（例如 `--dart-define`）统一管理。

### Android 启动图标

Android 端启动图标在：

- `android/app/src/main/res/mipmap-*/ic_launcher.png`

并在 `android/app/src/main/AndroidManifest.xml` 通过 `android:icon="@mipmap/ic_launcher"` 引用。

## 常见问题（FAQ）

### 1) 为什么上传后任务状态一直在 SCANNING？

可能是后端分析队列在排队，或网络/存储服务异常。建议先确认后端容器（MySQL/Redis/MinIO/后端服务）均正常运行，并查看后端日志定位原因。

### 2) 为什么“提取 APK”失败？

Android 版本/权限策略会影响读取应用 APK。请确认已授予存储相关权限，并优先在真机上测试。

## License

本项目用于学习与研究用途。
