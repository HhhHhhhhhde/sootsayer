package com.example.myapp;

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
    private static final String CHANNEL = "com.example.myapp/apk";

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
                    Map<String, Object> extractResult = extractApk(packageName);
                    if (extractResult.containsKey("error")) {
                        result.error("EXTRACT_ERROR", (String) extractResult.get("error"), null);
                    } else {
                        result.success(extractResult);
                    }
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
            String sourceDir = appInfo.publicSourceDir;
            
            File sourceFile = new File(sourceDir);
            if (!sourceFile.exists()) {
                result.put("error", "APK 文件不存在");
                return result;
            }

            // 获取应用名称
            String appName = appInfo.loadLabel(pm).toString();
            String versionName = "";
            try {
                PackageInfo packageInfo = pm.getPackageInfo(packageName, 0);
                versionName = packageInfo.versionName != null ? packageInfo.versionName : "";
            } catch (Exception e) {
                versionName = "unknown";
            }

            // 创建输出目录
            File outputDir = new File(Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS), "ExtractedAPKs");
            if (!outputDir.exists()) {
                outputDir.mkdirs();
            }

            // 生成输出文件名
            String outputFileName = appName + "_" + versionName + ".apk";
            outputFileName = outputFileName.replaceAll("[^a-zA-Z0-9._-]", "_");
            File outputFile = new File(outputDir, outputFileName);

            // 复制 APK 文件
            FileInputStream fis = new FileInputStream(sourceFile);
            FileOutputStream fos = new FileOutputStream(outputFile);
            byte[] buffer = new byte[1024 * 8];
            int length;
            while ((length = fis.read(buffer)) > 0) {
                fos.write(buffer, 0, length);
            }
            fos.close();
            fis.close();

            // 返回结果
            result.put("success", true);
            result.put("outputPath", outputFile.getAbsolutePath());
            result.put("size", outputFile.length());
            result.put("appName", appName);
            result.put("versionName", versionName);
            
        } catch (Exception e) {
            result.put("error", "提取失败: " + e.getMessage());
        }
        return result;
    }
}
