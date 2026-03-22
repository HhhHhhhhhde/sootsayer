# Flutter 国内镜像配置说明

## 已完成的配置

### 1. Gradle 镜像配置 ✅
已在以下文件中配置阿里云镜像：
- `android/build.gradle.kts` - Maven 仓库镜像
- `android/settings.gradle.kts` - 插件仓库镜像
- `android/gradle/wrapper/gradle-wrapper.properties` - Gradle 分发包镜像（腾讯云）

### 2. Flutter Pub 镜像配置（可选）

如果 Flutter pub get 也很慢，可以配置以下环境变量：

#### Windows PowerShell:
```powershell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
```

#### Windows CMD:
```cmd
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

#### 永久配置（推荐）:
在系统环境变量中添加：
- 变量名: `PUB_HOSTED_URL`
  值: `https://pub.flutter-io.cn`
- 变量名: `FLUTTER_STORAGE_BASE_URL`
  值: `https://storage.flutter-io.cn`

## 清理并重新构建

配置完成后，执行以下命令：

```bash
cd d:/codes/Android/myapp

# 清理之前的构建
flutter clean

# 重新获取依赖
flutter pub get

# 运行应用
flutter run
```

## 镜像源说明

- **Maven 仓库**: 阿里云镜像 (maven.aliyun.com)
- **Gradle 分发**: 腾讯云镜像 (mirrors.cloud.tencent.com)
- **Flutter Pub**: 上海交大镜像 (pub.flutter-io.cn)

这些镜像都是国内访问速度较快的源。
