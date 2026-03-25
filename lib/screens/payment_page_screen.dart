import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
 bool _formSubmitted = false;
 Timer? _checkTimer;

 @override
 void initState() {
 super.initState();
 _initializeWebView();
 _startPaymentStatusCheck();
 }

 String _normalizeHtml(String raw) {
 var html = raw.trim();

 html = html
 .replaceAll(r'\n', '\n')
 .replaceAll(r'\r', '\r')
 .replaceAll(r'\t', '\t')
 .replaceAll(r'\"', '"')
 .replaceAll(r"\'", "'");

 if (html.contains('&quot;')) {
 html = html.replaceAll('&quot;', '"');
 }

 // 后端偶发返回重复网关路径，导致支付宝直接502
 html = html.replaceAll(
 'https://openapi.alipaydev.com/gateway.do/gateway.do',
 'https://openapi.alipaydev.com/gateway.do',
 );

 return html;
 }

 String _appendAutoSubmitScript(String html) {
 const script = '''
<script>
(function() {
 function autoSubmit() {
 var form = document.forms['punchout_form'] || document.querySelector('form');
 if (!form) return false;
 if (form.dataset.__submitted === '1') return true;
 form.dataset.__submitted = '1';
 form.submit();
 return true;
 }

 function ensureSubmit() {
 if (autoSubmit()) return;
 var tries =0;
 var timer = setInterval(function() {
 tries++;
 if (autoSubmit() || tries >=20) {
 clearInterval(timer);
 }
 },150);
 }

 if (document.readyState === 'loading') {
 document.addEventListener('DOMContentLoaded', ensureSubmit);
 } else {
 ensureSubmit();
 }
 window.addEventListener('load', ensureSubmit);
})();
</script>
''';

 final hasHtmlTag = html.toLowerCase().contains('<html');
 if (!hasHtmlTag) {
 return '''
<!DOCTYPE html>
<html>
<head>
 <meta charset="utf-8" />
 <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body>
$html
$script
</body>
</html>
''';
 }

 if (html.contains('</body>')) {
 return html.replaceFirst('</body>', '$script</body>');
 }

 return '$html$script';
 }

 Future<void> _tryAutoSubmitForm() async {
 if (_formSubmitted) return;

 try {
 final result = await _webViewController.runJavaScriptReturningResult('''
(function() {
 var form = document.forms['punchout_form'] || document.querySelector('form');
 if (!form) return 'NO_FORM';
 if (form.dataset.__submitted === '1') return 'ALREADY_SUBMITTED';
 form.dataset.__submitted = '1';
 form.submit();
 return 'SUBMITTED';
})();
''');

 print('Auto submit result: $result');
 if (result.toString().contains('SUBMITTED') ||
 result.toString().contains('ALREADY_SUBMITTED')) {
 _formSubmitted = true;
 }
 } catch (e) {
 print('Auto submit form error: $e');
 }
 }

 void _initializeWebView() {
 final normalizedHtml = _normalizeHtml(widget.htmlContent);
 final htmlForWebView = _appendAutoSubmitScript(normalizedHtml);
 final htmlBase64 = base64Encode(utf8.encode(htmlForWebView));
 final dataUri = Uri.parse('data:text/html;base64,$htmlBase64');

 print('Prepared payment HTML length: ${htmlForWebView.length}');
 print('WebView JavaScript mode: unrestricted');
 print('Loading payment HTML via Base64 data URI');

 _webViewController = WebViewController()
 ..setJavaScriptMode(JavaScriptMode.unrestricted)
 ..addJavaScriptChannel(
 'PaymentComplete',
 onMessageReceived: (JavaScriptMessage message) {
 print('Payment completed: ${message.message}');
 _verifyPaymentWithBackend();
 },
 )
 ..setNavigationDelegate(
 NavigationDelegate(
 onPageStarted: (String url) {
 if (!mounted) return;
 setState(() => _isLoading = true);
 print('Page started: $url');
 },
 onPageFinished: (String url) {
 if (!mounted) return;
 setState(() => _isLoading = false);
 print('Page finished: $url');
 _tryAutoSubmitForm();
 _checkPaymentStatus();
 },
 onWebResourceError: (WebResourceError error) {
 print('WebView error: ${error.description}');
 },
 onNavigationRequest: (NavigationRequest request) {
 print('Navigation request: ${request.url}');
 if (request.url.contains('success') ||
 request.url.contains('return_url') ||
 request.url.contains('notify')) {
 _verifyPaymentWithBackend();
 return NavigationDecision.prevent;
 }
 return NavigationDecision.navigate;
 },
 ),
 )
 ..loadRequest(dataUri);
 }

 void _startPaymentStatusCheck() {
 _checkTimer = Timer.periodic(const Duration(seconds:2), (timer) {
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
 var htmlText = (document.documentElement?.innerHTML || '').toLowerCase();

 if (bodyText.includes('成功') ||
 bodyText.includes('success') ||
 bodyText.includes('complete') ||
 bodyText.includes('已支付') ||
 bodyText.includes('支付成功') ||
 bodyText.includes('交易成功') ||
 bodyText.includes('payment successful') ||
 htmlText.includes('success') ||
 htmlText.includes('complete')) {
 window.PaymentComplete.postMessage('success');
 }
})();
''')
 .catchError((e) {
 print('JavaScript execution error: $e');
 });
 }

 Future<void> _verifyPaymentWithBackend() async {
 if (_paymentCompleted || _isVerifying) return;

 if (mounted) {
 setState(() => _isVerifying = true);
 }
 _checkTimer?.cancel();

 try {
 final authProvider = Provider.of<AuthProvider>(context, listen: false);
 final result = await authProvider.verifyPayment(widget.outTradeNo);

 if (!mounted) return;

 print('Payment verification result: $result');

 if (result == 'SUCCESS' || result == 'ALREADY_CREDITED') {
 await _handlePaymentSuccess();
 } else if (result == 'PENDING') {
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(
 content: Text('支付处理中，请稍候...'),
 duration: Duration(seconds:2),
 ),
 );
 setState(() => _isVerifying = false);
 } else {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text('支付验证失败: $result'),
 backgroundColor: Colors.red,
 ),
 );
 setState(() => _isVerifying = false);
 }
 } catch (e) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text('验证支付出错: $e'),
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

 if (mounted) {
 Navigator.pop(context, true);
 }
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
 title: Text('${widget.paymentMethod == 'WECHAT' ? '微信' : '支付宝'}支付'),
 leading: IconButton(
 icon: const Icon(Icons.arrow_back),
 onPressed: () => Navigator.pop(context, false),
 ),
 ),
 body: Stack(
 children: [
 WebViewWidget(controller: _webViewController),
 if (_isLoading) const Center(child: CircularProgressIndicator()),
 ],
 ),
 floatingActionButton: !_paymentCompleted
 ? FloatingActionButton.extended(
 onPressed: () => Navigator.pop(context, false),
 tooltip: '取消支付',
 icon: const Icon(Icons.close),
 label: const Text('取消支付'),
 )
 : null,
 );
 }
}
