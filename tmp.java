package com.example.apk_extraction;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Environment;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.apk_extraction/apk";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("getInstalledApps")) {
                    List<Map<String, String>> apps = getInstalledApps();
                    result.success(apps);
                } else if (call.method.equals("extractApk")) {
                    String packageName = call.argument("packageName");
                    MethodChannel.Result finalResult = result;
                    new Thread(() -> {
                        Map<String, Object> extractResult = extractApk(packageName);
                        if (extractResult.containsKey("error")) {
                            finalResult.error("EXTRACT_ERROR", (String) extractResult.get("error"), null);
                        } else {
                            finalResult.success(extractResult);
                        }
                    }).start();
                } else {
                    result.notImplemented();
                }
            });
    }

    private List<Map<String, String>> getInstalledApps() {
        List<Map<String, String>> appList = new ArrayList<>();
        PackageManager pm = getPackageManager();
        List<PackageInfo> packages = pm.getInstalledPackages(0);

        for (PackageInfo packageInfo : packages) {
            Map<String, String> appInfo = new HashMap<>();
            appInfo.put("packageName", packageInfo.packageName);
            appInfo.put("appName", packageInfo.applicationInfo.loadLabel(pm).toString());
            appInfo.put("versionName", packageInfo.versionName != null ? packageInfo.versionName : "");
            appList.add(appInfo);
        }
        return appList;
    }

    private Map<String, Object> extractApk(String packageName) {
        Map<String, Object> result = new HashMap<>();
        try {
            PackageManager pm = getPackageManager();
            ApplicationInfo appInfo = pm.getApplicationInfo(packageName, 0);
            
            // 获取应用名称和版本
            String appName = appInfo.loadLabel(pm).toString();
            String versionName = "";
            try {
                PackageInfo packageInfo = pm.getPackageInfo(packageName, 0);
                versionName = packageInfo.versionName != null ? packageInfo.versionName : "";
            } catch (Exception e) {
                versionName = "unknown";
            }

            // 创建输出目录（使用应用私有缓存目录，无需危险权限）
            File cacheDir = getExternalCacheDir();
            if (cacheDir == null) {
                result.put("error", "无法访问缓存目录");
                return result;
            }

            File outputDir = new File(cacheDir, "ExtractedAPKs");
            if (!outputDir.exists()) {
                outputDir.mkdirs();
            }

            // 生成输出文件夹名称
            String folderName = appName + "_" + versionName;
            folderName = folderName.replaceAll("[^a-zA-Z0-9._-]", "_");
            File appOutputDir = new File(outputDir, folderName);
            if (!appOutputDir.exists()) {
                appOutputDir.mkdirs();
            }

            List<String> extractedFiles = new ArrayList<>();
            long totalSize = 0;

            // 提取 base APK
            String sourceDir = appInfo.publicSourceDir;
            File sourceFile = new File(sourceDir);
            if (sourceFile.exists()) {
                String baseFileName = "base.apk";
                File outputFile = new File(appOutputDir, baseFileName);
                copyFile(sourceFile, outputFile);
                extractedFiles.add(baseFileName);
                totalSize += outputFile.length();
            } else {
                result.put("error", "Base APK 文件不存在");
                return result;
            }

            // 提取 Split APKs
            if (appInfo.splitPublicSourceDirs != null && appInfo.splitPublicSourceDirs.length > 0) {
                for (int i = 0; i < appInfo.splitPublicSourceDirs.length; i++) {
                    String splitDir = appInfo.splitPublicSourceDirs[i];
                    File splitFile = new File(splitDir);
                    if (splitFile.exists()) {
                        String splitFileName = "split_" + i + ".apk";
                        File outputFile = new File(appOutputDir, splitFileName);
                        copyFile(splitFile, outputFile);
                        extractedFiles.add(splitFileName);
                        totalSize += outputFile.length();
                    }
                }
            }

            // 返回结果
            result.put("success", true);
            result.put("outputPath", appOutputDir.getAbsolutePath());
            result.put("extractedFiles", extractedFiles);
            result.put("totalSize", totalSize);
            result.put("appName", appName);
            result.put("versionName", versionName);
            
        } catch (Exception e) {
            result.put("error", "提取失败: " + e.getMessage());
        }
        return result;
    }

    private void copyFile(File source, File destination) throws Exception {
        try (FileInputStream fis = new FileInputStream(source);
             FileOutputStream fos = new FileOutputStream(destination)) {
            byte[] buffer = new byte[1024 * 8];
            int length;
            while ((length = fis.read(buffer)) > 0) {
                fos.write(buffer, 0, length);
            }
        }
    }
}
