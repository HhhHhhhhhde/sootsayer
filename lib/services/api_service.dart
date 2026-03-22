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
      
      print('Send verify code request: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-code/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Send verify code response status: ${response.statusCode}');
      print('Send verify code response body: ${response.body}');

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
      
      print('Register request: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

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
        print('Login response: $result');
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
      
      print('Reset password request: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Reset password response status: ${response.statusCode}');
      print('Reset password response body: ${response.body}');

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
      print('Get user info with token: $token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/user/info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get user info response status: ${response.statusCode}');
      print('Get user info response body: ${response.body}');

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
      print('Upload file: $filePath with token: $token');
      print(1);
      print('$token');
      
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

      print('Upload file response status: ${response.statusCode}');
      print('Upload file response body: $responseBody');

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

      print('Erase account response status: ${response.statusCode}');
      print('Erase account response body: ${response.body}');

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

      print('Recharge response status: ${response.statusCode}');
      print('Recharge response body: ${response.body}');

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

  // 获取支付页面 HTML
  static Future<Map<String, dynamic>> getPaymentPage(
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

      print('Get payment page response status: ${response.statusCode}');
      print('Get payment page response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        return {
          'code': response.statusCode,
          'message': '获取支付页面失败',
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
