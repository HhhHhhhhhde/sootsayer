import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../providers/auth_provider.dart';

class PaymentPageScreen extends StatefulWidget {
  final String htmlContent;
  final String paymentMethod;
  final double amount;
  final String outTradeNo;

  const PaymentPageScreen({
    super.key,
    required this.htmlContent,
    required this.paymentMethod,
    required this.amount,
    required this.outTradeNo,
  });

  @override
  State<PaymentPageScreen> createState() => _PaymentPageScreenState();
}

class _PaymentPageScreenState extends State<PaymentPageScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _paymentCompleted = false;
  bool _isVerifying = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startPaymentStatusCheck();
  }

  String _normalizeHtml(String raw) {
    // 暂时不做任何清洗，直接把后端返回的 HTML 原样传给 WebView。
    return raw;
  }

  /// 与表单 `action` 一致，避免 `data:` 源导致提交到网关时 TLS/安全上下文异常。
  String _alipayHtmlBaseUrl(String html) {
    if (html.contains('openapi-sandbox.dl.alipaydev.com')) {
      return 'https://openapi-sandbox.dl.alipaydev.com/';
    }
    return 'https://openapi.alipaydev.com/';
  }

  void _initializeWebView() {
    debugPrint('[PaymentPage] initWebView outTradeNo=${widget.outTradeNo} amount=${widget.amount}');
    final html = _normalizeHtml(widget.htmlContent);
    final baseUrl = _alipayHtmlBaseUrl(html);
    debugPrint('[PaymentPage] loadHtmlString baseUrl=$baseUrl htmlLen=${html.length}');

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaymentComplete',
        onMessageReceived: (JavaScriptMessage message) {
          _verifyPaymentWithBackend();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('[PaymentPage] onPageStarted: $url');
            if (!mounted) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            debugPrint('[PaymentPage] onPageFinished: $url');
            if (!mounted) return;
            setState(() => _isLoading = false);
            _checkPaymentStatus();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[PaymentPage] WebView error [${error.errorCode}]: ${error.description} url=${error.url}',
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('[PaymentPage] onNavigationRequest: $url');
            if (url.contains('return_url') ||
                url.contains('notify') ||
                (url.contains('success') && !url.contains('alipay'))) {
              _verifyPaymentWithBackend();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // `data:` 文档无 HTTPS 源，表单 POST 到 openapi.alipaydev.com 时易出现握手失败或连接被重置。
    // 使用网关域作为 baseUrl，并允许沙箱页内混合内容（Android）。
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final c = _webViewController;
      if (c.platform is AndroidWebViewController) {
        await (c.platform as AndroidWebViewController)
            .setMixedContentMode(MixedContentMode.alwaysAllow);
      }
      await c.loadHtmlString(html, baseUrl: baseUrl);
    });
  }

  void _startPaymentStatusCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_paymentCompleted && mounted) {
        _checkPaymentStatus();
      }
    });
  }

  void _checkPaymentStatus() {
    _webViewController
        .runJavaScript('''
(function() {
  var bodyText = (document.body?.innerText || '').toLowerCase();
  if (bodyText.includes('\u652f\u4ed8\u6210\u529f') ||
      bodyText.includes('\u4ea4\u6613\u6210\u529f') ||
      bodyText.includes('\u5df2\u652f\u4ed8') ||
      bodyText.includes('payment successful') ||
      bodyText.includes('trade success')) {
    window.PaymentComplete.postMessage('success');
  }
})();
''')
        .catchError((_) {});
  }

  Future<void> _verifyPaymentWithBackend() async {
    if (_paymentCompleted || _isVerifying) return;
    debugPrint('[PaymentPage] verifyPaymentWithBackend outTradeNo=${widget.outTradeNo}');
    if (mounted) setState(() => _isVerifying = true);
    _checkTimer?.cancel();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.verifyPayment(widget.outTradeNo);
      debugPrint('[PaymentPage] verifyPayment result: $result');

      if (!mounted) return;

      if (result == 'SUCCESS' || result == 'ALREADY_CREDITED') {
        debugPrint('[PaymentPage] payment SUCCESS');
        await _handlePaymentSuccess();
      } else if (result == 'PENDING') {
        debugPrint('[PaymentPage] payment PENDING');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u652f\u4ed8\u5904\u7406\u4e2d\uff0c\u8bf7\u7a0d\u5019...'),
            duration: Duration(seconds: 2),
          ),
        );
        if (mounted) setState(() => _isVerifying = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u652f\u4ed8\u9a8c\u8bc1\u5931\u8d25: $result'),
            backgroundColor: Colors.red,
          ),
        );
        if (mounted) setState(() => _isVerifying = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u9a8c\u8bc1\u652f\u4ed8\u51fa\u9519: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _handlePaymentSuccess() async {
    if (_paymentCompleted) return;
    _paymentCompleted = true;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.getBalance();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.paymentMethod == 'WECHAT' ? '\u5fae\u4fe1' : '\u652f\u4ed8\u5b9d'}\u652f\u4ed8'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading || _isVerifying)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: !_paymentCompleted
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'pay_refresh',
                  onPressed: _isVerifying ? null : _verifyPaymentWithBackend,
                  tooltip: '\u6211\u5df2\u652f\u4ed8\uff0c\u5237\u65b0\u4f59\u989d',
                  icon: const Icon(Icons.refresh),
                  label: const Text('\u6211\u5df2\u652f\u4ed8'),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'pay_cancel',
                  onPressed: () => Navigator.pop(context, false),
                  tooltip: '\u53d6\u6d88\u652f\u4ed8',
                  icon: const Icon(Icons.close),
                  label: const Text('\u53d6\u6d88\u652f\u4ed8'),
                ),
              ],
            )
          : null,
    );
  }
}
