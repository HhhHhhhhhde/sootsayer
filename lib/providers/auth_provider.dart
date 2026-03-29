import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _sessionToken;
  bool _isLoading = false;
  String? _errorMessage;

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

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
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

      final code = result['code'];
      final isSuccess = code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess) {
        _isLoggedIn = true;
        _userEmail = email;
        _sessionToken = result['data']?.toString() ??
            'token_${DateTime.now().millisecondsSinceEpoch}';
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
      final result =
          await ApiService.resetPassword(email, verifyCode, newPassword);
      _isLoading = false;

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

  /// 获取支付页面数据（outTradeNo + HTML表单）.
  /// 后端现在返回 PaymentResult 结构体，outTradeNo 在 JSON 中直接可用，
  /// 无需在 WebView 中解析 HTML.
  Future<Map<String, dynamic>?> getPaymentPage(
      double amount, String payMethod) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[Payment] getPaymentPage called: amount=$amount method=$payMethod');
      final result = await ApiService.getPaymentPage(
        _sessionToken ?? '',
        amount,
        payMethod,
      );
      _isLoading = false;
      debugPrint('[Payment] raw backend response: $result');

      final code = result['code'];
      final isSuccess =
          code == 200 || code == 0 || code == '200' || code == '0';
      if (!isSuccess) {
        _errorMessage = result['msg'] ?? result['message'] ?? '获取支付页面失败';
        debugPrint('[Payment] backend returned error: code=$code msg=$_errorMessage');
        notifyListeners();
        return {
          'code': result['code'] ?? 500,
          'message': _errorMessage,
          'htmlContent': null,
          'outTradeNo': null,
        };
      }

      // 后端返回 Result<PaymentResult>:
      // data = { outTradeNo, paymentUrl (支付宝HTML表单), qrCode, expireTime }
      final data = result['data'];
      debugPrint('[Payment] data field type: ${data.runtimeType}');
      debugPrint('[Payment] data value: $data');

      if (data is! Map<String, dynamic>) {
        _errorMessage = '支付数据格式错误';
        debugPrint('[Payment] ERROR: data is not a Map, got ${data.runtimeType}');
        notifyListeners();
        return {
          'code': -1,
          'message': _errorMessage,
          'htmlContent': null,
          'outTradeNo': null,
        };
      }

      final htmlContent = data['paymentUrl']?.toString() ??
          data['htmlContent']?.toString() ??
          data['html']?.toString() ??
          '';
      final outTradeNo = data['outTradeNo']?.toString() ??
          data['out_trade_no']?.toString() ??
          '';

      debugPrint('[Payment] outTradeNo: $outTradeNo');
      debugPrint('[Payment] htmlContent length: ${htmlContent.length}');
      debugPrint('[Payment] htmlContent preview: ${htmlContent.length > 200 ? htmlContent.substring(0, 200) : htmlContent}');

      if (htmlContent.isEmpty) {
        _errorMessage = '支付页面数据为空';
        debugPrint('[Payment] ERROR: htmlContent is empty, data keys: ${data.keys.toList()}');
        notifyListeners();
        return {
          'code': -1,
          'message': _errorMessage,
          'htmlContent': null,
          'outTradeNo': null,
        };
      }

      if (outTradeNo.isEmpty) {
        _errorMessage = '订单号缺失，无法完成支付验证';
        debugPrint('[Payment] ERROR: outTradeNo is empty, data keys: ${data.keys.toList()}');
        notifyListeners();
        return {
          'code': -1,
          'message': _errorMessage,
          'htmlContent': null,
          'outTradeNo': null,
        };
      }

      debugPrint('[Payment] getPaymentPage SUCCESS: outTradeNo=$outTradeNo htmlLen=${htmlContent.length}');
      return {
        'code': 200,
        'message': 'success',
        'htmlContent': htmlContent,
        'outTradeNo': outTradeNo,
      };
    } catch (e) {
      _isLoading = false;
      _errorMessage = '网络错误: $e';
      debugPrint('[Payment] EXCEPTION in getPaymentPage: $e');
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

      final code = result['code'];
      final isSuccess =
          code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess && result['data'] != null) {
        final data = result['data'];
        if (data is num) return data.toDouble();
        if (data is String) return double.tryParse(data);
        return 0.0;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> verifyPayment(String outTradeNo) async {
    try {
      final result = await ApiService.verifyPayment(
        _sessionToken ?? '',
        outTradeNo,
      );

      final code = result['code'];
      final isSuccess =
          code == 200 || code == 0 || code == '200' || code == '0';

      if (isSuccess && result['data'] != null) {
        return result['data'].toString();
      } else {
        _errorMessage = result['message'] ?? '验证支付失败';
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> subscribePlan(String planType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result =
          await ApiService.subscribePlan(_sessionToken ?? '', planType);
      _isLoading = false;

      final code = result['code'];
      final isSuccess =
          code == 200 || code == 0 || code == '200' || code == '0';

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
      final result =
          await ApiService.getCurrentSubscription(_sessionToken ?? '');

      final code = result['code'];
      final isSuccess =
          code == 200 || code == 0 || code == '200' || code == '0';

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
