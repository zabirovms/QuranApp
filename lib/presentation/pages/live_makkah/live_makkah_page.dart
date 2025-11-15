import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveMakkahPage extends StatefulWidget {
  const LiveMakkahPage({super.key});

  @override
  State<LiveMakkahPage> createState() => _LiveMakkahPageState();
}

class _LiveMakkahPageState extends State<LiveMakkahPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool? _pageLoaded;
  DateTime? _pageLoadTime;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  void _initializeWebView() {
    // Use YouTube embed format with specific live stream video ID
    // Video ID: 7-Qf3g-0xEI from https://www.youtube.com/live/7-Qf3g-0xEI
    final embedUrl = 'https://www.youtube.com/embed/7-Qf3g-0xEI?autoplay=1&mute=0&controls=1&rel=0&modestbranding=1&playsinline=1';
    
    // Create minimal HTML with just the embed iframe
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
        iframe { width: 100%; height: 100%; border: none; }
    </style>
</head>
<body>
    <iframe src="$embedUrl" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen frameborder="0"></iframe>
</body>
</html>
    ''';
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
              _pageLoaded = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _pageLoaded = true;
              _pageLoadTime = DateTime.now();
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Don't show errors if page just loaded (give it time to stabilize)
            if (_pageLoadTime != null) {
              final timeSinceLoad = DateTime.now().difference(_pageLoadTime!);
              if (timeSinceLoad.inSeconds < 3) {
                // Ignore errors within 3 seconds of page load
                return;
              }
            }
            
            // Ignore common non-critical errors:
            // -3: File not found (common for YouTube resources)
            // -8: Timeout (can happen with slow connections)
            // -2: Host lookup failed (can be temporary)
            // -6: Connection failed (can be temporary)
            if (error.errorCode == -3 || 
                error.errorCode == -8 || 
                error.errorCode == -2 || 
                error.errorCode == -6) {
              return;
            }
            
            // Only show critical errors after page has loaded
            if (_pageLoaded == true) {
              setState(() {
                _errorMessage = 'Хатогӣ дар боркунии видео: ${error.description}';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            // Allow YouTube and Google domains for video resources
            if (uri.host.contains('youtube.com') || 
                uri.host.contains('youtu.be') ||
                uri.host.contains('google.com') ||
                uri.host.contains('googleapis.com') ||
                uri.host.contains('gstatic.com') ||
                uri.host.contains('ggpht.com') ||
                uri.host.contains('ytimg.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..loadHtmlString(htmlContent, baseUrl: 'https://www.youtube.com');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Маккаи Мукаррама - Пахш зинда'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Аз нав бор кардан',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Боркунии пахш...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Error message
          if (_errorMessage != null && !_isLoading)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Аз нав кӯшиш кардан'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

