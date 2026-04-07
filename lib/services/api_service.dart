import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // 发送验证码
  static Future<Map<String, dynamic>> sendVerifyCode(
    String email,
    String type,
  ) async {
    try {
    final requestBody = {
        'email': email,
        'type': type,
      };
      
      debugPrint('Send verify code request: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-code/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Send verify code response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'code': response.statusCode,
          'message': '发送验证码失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 用户注册
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String verifyCode, {
    String? username,
    String? phone,
  }) async {
    try {
      final requestBody = {
        'email': email,
        'password': password,
        'verifyCode': verifyCode,
      };
      
      if (username != null) {
        requestBody['username'] = username;
      }
      if (phone != null) {
        requestBody['phone'] = phone;
      }
      
      debugPrint('Register request: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Register response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'code': response.statusCode,
          'message': '注册失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 用户登录
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'account': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('Login response: $result');
        return result;
      } else {
        return {
          'code': response.statusCode,
          'message': '登录失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 退出登录
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'code': response.statusCode,
          'message': '退出登录失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 修改密码
  static Future<Map<String, dynamic>> changePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/password/change'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'code': response.statusCode,
          'message': '修改密码失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 重置密码
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String verifyCode,
    String newPassword,
  ) async {
    try {
      final requestBody = {
        'email': email,
        'verifyCode': verifyCode,
        'newPassword': newPassword,
      };
      
      debugPrint('Reset password request: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Reset password response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'code': response.statusCode,
          'message': '重置密码失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 获取用户信息
  static Future<Map<String, dynamic>> getUserInfo(String token) async {
    try {
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/user/info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get user info response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'code': response.statusCode,
          'message': '获取用户信息失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 上传文件
  static Future<Map<String, dynamic>> uploadFile(String filePath, String token) async {
    try {
      debugPrint('Upload file:');
      debugPrint('$token');
      
      final file = File(filePath);
      if (!file.existsSync()) {
        return {
          'code': 400,
          'message': '文件不存在',
          'data': null,
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/files/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Upload file response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        return {
          'code': response.statusCode,
          'message': '上传文件失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 注销账户
  static Future<Map<String, dynamic>> eraseAccount(
    String token,
    String verifyPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/privacy/data/erase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'verifyPassword': verifyPassword,
        }),
      );

      debugPrint('Erase account response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'code': response.statusCode,
          'message': '注销账户失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 充值
  static Future<Map<String, dynamic>> recharge(
    String token,
    double amount,
    String payMethod,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/assets/recharge').replace(
        queryParameters: {
          'amount': amount.toString(),
          'payMethod': payMethod,
        },
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Recharge response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        return {
          'code': response.statusCode,
          'message': '充值失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 兼容旧调用：后端已改为直接调用充值接口，不再返回支付页面 HTML
  static Future<Map<String, dynamic>> getPaymentPage(
    String token,
    double amount,
    String payMethod,
  ) async {
    return recharge(token, amount, payMethod);
  }

 // 获取账户余额（GET /api/assets/balance）
 static Future<Map<String, dynamic>> getBalance(String token) async {
 try {
 final response = await http.get(
 Uri.parse('$baseUrl/assets/balance'),
 headers: {
 'Content-Type': 'application/json',
 'Authorization': 'Bearer $token',
 },
 );

 if (response.statusCode !=200) {
 return {
 'code': response.statusCode,
 'message': '获取余额失败',
 'data': null,
 };
 }

 final result = jsonDecode(response.body) as Map<String, dynamic>;
 final code = result['code'];
 final isSuccess = code ==200 || code ==0 || code == '200' || code == '0';
 if (!isSuccess) {
 return result;
 }

 final data = result['data'];
 double? balance;

 if (data is num) {
 balance = data.toDouble();
 } else if (data is String) {
 balance = double.tryParse(data);
 } else if (data is Map<String, dynamic>) {
 final amountRaw = data['balance'] ?? data['amount'] ?? data['value'];
 if (amountRaw is num) {
 balance = amountRaw.toDouble();
 } else {
 balance = double.tryParse(amountRaw?.toString() ?? '');
 }
 }

 return {
 'code': code,
 'message': result['message'] ?? result['msg'] ?? 'success',
 'data': balance ??0.0,
 };
 } catch (e) {
 return {
 'code': -1,
 'message': '网络错误: $e',
 'data': null,
 };
 }
 }

  // 查询支付状态（后端接口：GET /api/payment/status/{outTradeNo}）
  static Future<Map<String, dynamic>> verifyPayment(
    String token,
    String outTradeNo,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/status/$outTradeNo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        'code': response.statusCode,
        'message': '验证支付失败',
        'data': null,
      };
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }

  // 订阅套餐
 static Future<Map<String, dynamic>> subscribePlan(
 String token,
 String planType,
 ) async {
 try {
 final uri = Uri.parse('$baseUrl/subscriptions').replace(
 queryParameters: {
 'planType': planType,
 },
 );

 final response = await http.post(
 uri,
 headers: {
 'Content-Type': 'application/json',
 'Authorization': 'Bearer $token',
 },
 );

 if (response.statusCode ==200) {
 return jsonDecode(response.body);
 } else {
 return {
 'code': response.statusCode,
 'message': '订阅失败',
 'data': null,
 };
 }
 } catch (e) {
 return {
 'code': -1,
 'message': '网络错误: $e',
 'data': null,
 };
 }
 }

  // 取消任务
  static Future<Map<String, dynamic>> cancelTask(
    String token,
    int taskId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'code': response.statusCode, 'message': '取消任务失败', 'data': null};
    } catch (e) {
      return {'code': -1, 'message': '网络错误: $e', 'data': null};
    }
  }

  // 重试任务
  static Future<Map<String, dynamic>> retryTask(
    String token,
    int taskId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/retry'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'code': response.statusCode, 'message': '重试任务失败', 'data': null};
    } catch (e) {
      return {'code': -1, 'message': '网络错误: $e', 'data': null};
    }
  }

  // 获取语义分析报告
  static Future<Map<String, dynamic>> getSemanticReport(
    String token,
    int taskId,
  ) async {
    // 演示用伪造报告（taskId == -999）
    if (taskId == -999) {
      return {
        'code': 200,
        'message': 'success',
        'data': {
          'riskLevel': 'HIGH',
          'overallScore': 82,
          'summary': '该 APK 存在 4 条隐私数据泄露路径，其中 3 条为高危漏洞。应用在未经用户明确同意的情况下读取设备唯一标识符（IMEI）并通过网络接口上传至第三方服务器，同时将位置信息写入日志文件，存在严重违反《个人信息保护法》第十三条及 GDPR 第 5 条的行为。',
          'riskItems': [
            {
              'leakId': 1,
              'isTrueLeak': true,
              'riskLevel': 'HIGH',
              'riskScore': 92,
              'analysis': '应用通过 TelephonyManager.getDeviceId() 获取设备 IMEI 并上传至远程服务器。',
              'dataFlowExplanation': 'TelephonyManager.getDeviceId() -> HttpURLConnection.setRequestProperty() -> 网络上传',
              'legalImplications': '违反《个人信息保护法》第十三条，IMEI 属于个人信息，未经授权收集违法。',
              'remediation': '移除 getDeviceId() 调用，改用随机 UUID 替代设备标识。',
              'complianceReferences': ['个人信息保护法第十三条', 'GDPR第5条']
            },
            {
              'leakId': 2,
              'isTrueLeak': false,
              'riskLevel': 'LOW',
              'riskScore': 18,
              'analysis': 'Log.i() 输出用户名调试信息，但 Release 包中已通过 ProGuard 移除，判定为误报。',
              'dataFlowExplanation': 'userSession.getUsername() -> Log.i(TAG, message) -> Logcat（仅Debug）',
              'legalImplications': 'Release 版本中不构成实际泄露风险。',
              'remediation': '使用 BuildConfig.DEBUG 条件判断包裹所有日志调用。',
              'complianceReferences': ['Android安全最佳实践']
            },
          ]
        }
      };
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/$taskId/semantic'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'code': response.statusCode, 'message': '获取报告失败', 'data': null};
    } catch (e) {
      return {'code': -1, 'message': '网络错误: $e', 'data': null};
    }
  }

  // 获取任务历史列表
  static Future<Map<String, dynamic>> getTasks(
    String token, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'code': response.statusCode, 'message': '获取任务列表失败', 'data': null};
    } catch (e) {
      return {'code': -1, 'message': '网络错误: $e', 'data': null};
    }
  }

  // 获取单个任务状态
  static Future<Map<String, dynamic>> getTaskStatus(
    String token,
    int taskId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'code': response.statusCode, 'message': '获取任务状态失败', 'data': null};
    } catch (e) {
      return {'code': -1, 'message': '网络错误: $e', 'data': null};
    }
  }

  // 获取当前订阅
  static Future<Map<String, dynamic>> getCurrentSubscription(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/current'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'code': response.statusCode,
          'message': '获取当前订阅失败',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'code': -1,
        'message': '网络错误: $e',
        'data': null,
      };
    }
  }
}

