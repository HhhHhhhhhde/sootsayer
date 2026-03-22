# FlowDroid 移动端安全审计应用

这是一个基于 Flutter 开发的 Android 安全审计应用，用于提取已安装的 APK 文件并通过服务器端的 FlowDroid 和大模型进行安全分析，最终将漏洞信息呈现给用户。

## 功能特性

### 核心功能
- **仪表盘**：展示安全审计概览，包括审计追踪、安全指标和漏洞趋势
- **应用列表**：查看所有已审计的应用及其风险等级
- **应用详情**：查看单个应用的详细漏洞信息
- **设置**：管理应用主题、扫描设置和数据

### 界面特点
- 移动端优化的底部导航栏设计
- 支持深色/浅色主题切换
- Material Design 3 设计语言
- 响应式卡片布局
- 流畅的页面转场动画

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider
- **图表库**: FL Chart
- **UI 组件**: Material Design 3

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── providers/                         # 状态管理
│   ├── theme_provider.dart           # 主题管理
│   └── audit_provider.dart           # 审计数据管理
├── screens/                          # 页面
│   ├── home_screen.dart             # 主页（底部导航）
│   ├── dashboard_screen.dart        # 仪表盘
│   ├── app_list_screen.dart         # 应用列表
│   ├── app_detail_screen.dart       # 应用详情
│   └── settings_screen.dart         # 设置
└── widgets/                          # 组件
    ├── audit_tracker_card.dart      # 审计追踪卡片
    ├── security_metrics_card.dart   # 安全指标卡片
    └── vulnerability_trend_card.dart # 漏洞趋势图表
```

## 安装和运行

### 前置要求
- Flutter SDK 3.10.4 或更高版本
- Android Studio 或 VS Code
- Android 设备或模拟器

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd myapp
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

### 构建 APK
```bash
flutter build apk --release
```

## 依赖包

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  fl_chart: ^0.69.2
  shared_preferences: ^2.3.4
```

## 主要功能说明

### 1. 仪表盘
- 显示审计追踪进度
- 展示安全指标统计
- 漏洞趋势图表分析

### 2. 应用列表
- 列出所有已审计的应用
- 显示风险等级（低/中/高）
- 快速查看漏洞数量

### 3. 应用详情
- 应用基本信息
- 漏洞概览统计
- 详细漏洞列表

### 4. 设置
- 主题切换（深色/浅色）
- 扫描设置管理
- 数据导出和清除
- 关于信息

## 开发说明

### 添加新功能
1. 在 `lib/screens/` 创建新页面
2. 在 `lib/widgets/` 创建可复用组件
3. 使用 Provider 管理状态
4. 遵循 Material Design 设计规范

### 主题定制
在 `lib/providers/theme_provider.dart` 中修改主题配置：
```dart
ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  // 自定义其他主题属性
);
```

### 数据管理
使用 `AuditProvider` 管理审计数据：
```dart
// 添加审计数据
auditProvider.addAudit(auditData);

// 获取审计列表
final audits = auditProvider.audits;
```

## 后续开发计划

- [ ] 集成 APK 提取功能
- [ ] 实现服务器通信接口
- [ ] 添加实时扫描功能
- [ ] 实现自动扫描计划
- [ ] 添加报告导出功能
- [ ] 集成推送通知
- [ ] 添加用户认证

## 许可证

本项目仅供学习和研究使用。

## 联系方式

如有问题或建议，请提交 Issue。
