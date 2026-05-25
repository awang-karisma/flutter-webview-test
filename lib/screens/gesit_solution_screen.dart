import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Screen that opens https://app.gesitsolution.com in a WebView.
class GesitSolutionScreen extends StatefulWidget {
  const GesitSolutionScreen({super.key});

  @override
  State<GesitSolutionScreen> createState() => _GesitSolutionScreenState();
}

class _GesitSolutionScreenState extends State<GesitSolutionScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onUrlChange: (UrlChange url) {
            _currentUrl = url.url ?? '';
            final current = Uri.parse(_currentUrl);
            _currentPath = current.path;
            if (_currentPath.startsWith('/jobs/apply')) {
              Navigator.pushNamed(context, '/camera_qr');
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://app.gesitsolution.com'));

    if (mounted) {
      setState(() {});
    }
  }

  bool get _shouldShowAppBar {
    final uri = Uri.parse(_currentUrl);
    if (uri.path == '/') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(_currentUrl);
    return Scaffold(
      appBar: null,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF667eea)),
              ),

            Text('$_currentUrl - $_currentPath'), 
          ],
        ),
      ),
    );
  }
}
