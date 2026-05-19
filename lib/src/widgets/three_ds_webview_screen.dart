import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../errors.dart';
import '../services/payment_service.dart';

/// Internal full-screen WebView that hosts a 3DS / OTP challenge. Pops with:
///   - `ThreeDSChallengeResult` on a successful gateway redirect
///   - `MoamalatPaymentError` on a `WebResourceError`
///   - `null` if the user backs out
class ThreeDSWebViewScreen extends StatefulWidget {
  final MoamalatPaymentService service;
  final String threeDSUrl;
  final String title;

  const ThreeDSWebViewScreen({
    super.key,
    required this.service,
    required this.threeDSUrl,
    this.title = '3-D Secure',
  });

  static Route<Object?> route({
    required MoamalatPaymentService service,
    required String threeDSUrl,
    String title = '3-D Secure',
  }) {
    return MaterialPageRoute<Object?>(
      fullscreenDialog: true,
      builder: (_) => ThreeDSWebViewScreen(
        service: service,
        threeDSUrl: threeDSUrl,
        title: title,
      ),
    );
  }

  @override
  State<ThreeDSWebViewScreen> createState() => _ThreeDSWebViewScreenState();
}

class _ThreeDSWebViewScreenState extends State<ThreeDSWebViewScreen> {
  late final WebViewController _controller;
  bool _completed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (_completed) return;
            _completed = true;
            if (!mounted) return;
            Navigator.of(context).pop(
              MoamalatPaymentError(
                'WebView error during 3DS challenge: ${error.description}',
                cause: error,
              ),
            );
          },
          onNavigationRequest: (request) async {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.navigate;
            if (!widget.service.shouldHandleThreeDSRedirect(uri)) {
              return NavigationDecision.navigate;
            }
            if (_completed) return NavigationDecision.prevent;
            _completed = true;
            try {
              final result = await widget.service.handleThreeDSRedirect(
                uri,
              );
              if (!mounted) return NavigationDecision.prevent;
              Navigator.of(context).pop(result);
            } on MoamalatPaymentError catch (error) {
              if (!mounted) return NavigationDecision.prevent;
              Navigator.of(context).pop(error);
            } catch (error) {
              if (!mounted) return NavigationDecision.prevent;
              Navigator.of(context).pop(
                MoamalatPaymentError(
                  'Failed to verify 3DS redirect',
                  cause: error,
                ),
              );
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.threeDSUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_completed) return;
            _completed = true;
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
