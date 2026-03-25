import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _sessionToken;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 用户信息
  Map<String, dynamic>? _userInfo;

  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get sessionToken => _sessionToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userInfo => _userInfo;

  Future<bool> sendVerifyCode(String email, String type) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.sendVerifyCode(email, type);
      _isLoading = false;

      // 支持 200 和 0 两种成功码
      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        return true;
      } else {
        _errorMessage = result['msg'] ?? result['message'] ?? '发送验证码失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String verifyCode, {
    String? username,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.register(
        email,
        password,
        verifyCode,
        username: username,
        phone: phone,
      );
      _isLoading = false;

      // 支持 200 和 0 两种成功码
      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        // 注册成功后自动登录以获取真正的 JWT token
        return await login(email, password);
      } else {
        _errorMessage = result['message'] ?? '注册失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);
      _isLoading = false;

      print('AuthProvider login result: $result');
      print('Code value: ${result['code']}, type: ${result['code'].runtimeType}');

      // 检查响应码，支持 200 和 0 两种格式
      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      print('isSuccess: $isSuccess');

      if (isSuccess) {
        _isLoggedIn = true;
        _userEmail = email;
        
        // 从 data 中获取 token（后端返回的是 JWT token 字符串）
        _sessionToken = result['data']?.toString() ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
        
        print('Login successful, isLoggedIn: $_isLoggedIn, token: $_sessionToken');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['msg'] ?? result['message'] ?? '登录失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.logout(_sessionToken ?? '');
      _isLoading = false;

      _isLoggedIn = false;
      _userEmail = null;
      _sessionToken = null;
      notifyListeners();
      return result['code'] == 0;
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.changePassword(
        _sessionToken ?? '',
        oldPassword,
        newPassword,
      );
      _isLoading = false;

      // 支持 200 和 0 两种成功码
      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        return true;
      } else {
        _errorMessage = result['msg'] ?? result['message'] ?? '修改密码失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String verifyCode,
    String newPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.resetPassword(email, verifyCode, newPassword);
      _isLoading = false;

      // 支持 200 和 0 两种成功码
      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        return true;
      } else {
        _errorMessage = result['msg'] ?? result['message'] ?? '重置密码失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchUserInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getUserInfo(_sessionToken ?? '');
      _isLoading = false;

      // 支持 200 和 0 两种成功码
      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        _userInfo = result['data'];
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['msg'] ?? result['message'] ?? '获取用户信息失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eraseAccount(String verifyPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.eraseAccount(
        _sessionToken ?? '',
        verifyPassword,
      );
      _isLoading = false;

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        _isLoggedIn = false;
        _userEmail = null;
        _sessionToken = null;
        _userInfo = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['msg'] ?? result['message'] ?? '注销账户失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> recharge(double amount, String payMethod) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.recharge(
        _sessionToken ?? '',
        amount,
        payMethod,
      );
      _isLoading = false;

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        return true;
      } else {
        _errorMessage = result['msg'] ?? result['message'] ?? '充值失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPaymentPage(double amount, String payMethod) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.getPaymentPage(
        _sessionToken ?? '',
        amount,
        payMethod,
      );
      _isLoading = false;

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';
      if (!isSuccess) {
        _errorMessage = result['msg'] ?? result['message'] ?? '获取支付页面失败';
        notifyListeners();
        return {
          'code': result['code'] ?? 500,
          'message': _errorMessage,
          'htmlContent': null,
          'outTradeNo': null,
        };
      }

 final data = result['data'];
 print('responseData.data 原文: ${data is String ? data : jsonEncode(data)}');
 String htmlContent = '';
 String outTradeNo = '';

      if (data is String) {
        htmlContent = data;

        final outTradeNoMatch = RegExp(r'&quot;out_trade_no&quot;:&quot;([^&]+)&quot;')
            .firstMatch(data);
        if (outTradeNoMatch != null) {
          outTradeNo = outTradeNoMatch.group(1) ?? '';
        }
      } else if (data is Map<String, dynamic>) {
        htmlContent = data['html']?.toString() ?? data['htmlContent']?.toString() ?? '';
        outTradeNo = data['outTradeNo']?.toString() ?? data['out_trade_no']?.toString() ?? '';
      }

      if (htmlContent.isEmpty) {
        _errorMessage = '支付页面数据为空';
        notifyListeners();
        return {
          'code': -1,
          'message': _errorMessage,
          'htmlContent': null,
          'outTradeNo': null,
        };
      }

      return {
        'code': 200,
        'message': 'success',
        'htmlContent': htmlContent,
        'outTradeNo': outTradeNo,
      };
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return {
        'code': -1,
        'message': _errorMessage,
        'htmlContent': null,
        'outTradeNo': null,
      };
    }
  }

  Future<double?> getBalance() async {
    try {
      final result = await ApiService.getBalance(_sessionToken ?? '');

      print('getBalance result: $result');

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess && result['data'] != null) {
        final data = result['data'];
        if (data is num) {
          return data.toDouble();
        } else if (data is String) {
          return double.tryParse(data);
        }
        return 0.0;
      } else {
        print('Failed to get balance: ${result['message']}');
        return null;
      }
    } catch (e) {
      print('Error getting balance: $e');
      return null;
    }
  }

  Future<String?> verifyPayment(String outTradeNo) async {
    try {
      final result = await ApiService.verifyPayment(
        _sessionToken ?? '',
        outTradeNo,
      );

      print('verifyPayment result: $result');

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess && result['data'] != null) {
        return result['data'].toString();
      } else {
        _errorMessage = result['message'] ?? '验证支付失败';
        return null;
      }
    } catch (e) {
      print('Error verifying payment: $e');
      return null;
    }
  }

  Future<bool> subscribePlan(String planType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.subscribePlan(_sessionToken ?? '', planType);
      _isLoading = false;

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['msg'] ?? result['message'] ?? '订阅失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final result = await ApiService.getCurrentSubscription(_sessionToken ?? '');

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        return result['data'] as Map<String, dynamic>?;
      }

      _errorMessage = result['msg'] ?? result['message'] ?? '获取当前订阅失败';
      return null;
    } catch (e) {
      _errorMessage = '网络错误: $e';
      return null;
    }
  }
}
