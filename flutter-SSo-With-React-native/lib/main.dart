import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

import 'package:heartfulness/LoginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enabling debugging for Android web content
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Creating the main entry point of the Flutter app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heartfulness',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const NavigationExample(),
    );
  }
}

// NavigationExample is the main screen with tabs
class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});
  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

// Stateful widget for handling navigation and dynamic WebView display
class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0; // Tracks the currently selected tab
  bool showWebView = false; // Determines whether to show the WebView
  double progress = 0; // Tracks the loading progress of the WebView
  int videoIndexNumber = 3; // Tab index for the Videos page
  final GlobalKey webViewKey = GlobalKey(); // Key for identifying the WebView
  InAppWebViewController? webViewController; // WebView controller instance
  String? _refreshToken; // Access token for authentication, retrieved from SharedPreferences

  @override
  void initState() {
    super.initState();
    // Load access token on initialization
    _loadRefreshToken();
    // Clear cookies for a fresh session
    CookieManager.instance().clearCookies();
  }

  // Load access token from SharedPreferences
  Future<void> _loadRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('refresh_token');

    if (token != null) {
      setState(() {
        _refreshToken = token; // Set the token if found
      });
      debugPrint("refresh token loaded: $token");
    } else {
      debugPrint("No refresh token found."); // Log if no token is found
    }
  }

  // Handle bottom navigation and toggle WebView display
  void _handleNavigation(int index) {
    setState(() {
      currentPageIndex = index;
      showWebView = index == videoIndexNumber; // Show WebView only for Videos tab
    });
  }

  // Build the WebView widget for displaying web content
  Widget _buildWebView() {
    return SafeArea(
      child: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(
              url: WebUri("https://toonmania.dev.mogiio.tv?isIframe=true"),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true, // Enable JavaScript for interactivity
              mediaPlaybackRequiresUserGesture: false, // Autoplay media
              allowsInlineMediaPlayback: true, // Allow inline media playback
              iframeAllowFullscreen: true, // Allow full-screen iframes
              clearCache: true, // Clear cache for fresh content
            ),
            onWebViewCreated: (controller) {
              webViewController = controller; // Assign controller instance
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100; // Update progress bar
              });
            },
            // Handle WebView load completion and inject refresh token via JavaScript
            onLoadStop: (controller, url) async {
              // wait for web view loads completely
              await Future.delayed(Duration(seconds: 10));
              // Add JavaScript listener for messages from the WebView
              await controller.evaluateJavascript(source: '''
                      window.addEventListener("message", (event) => {
                        console.log("Received message in WebView:", event.data);
                      });
                      
                      var script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/eruda';
      script.onload = function() { eruda.init(); };
      document.body.appendChild(script);
                    ''');



              // Inject the  token as a message if available
              if (_refreshToken != null) {
                debugPrint("refreshToken_inside----->>: $_refreshToken");
                final escapedToken = _refreshToken!
                    .replaceAll("'", "\\'")
                    .replaceAll("\\", "\\\\"); // Escape special characters
                await controller.evaluateJavascript(source: '''
                    window.postMessage({ key: 'message', value: '$escapedToken' }, '*');
                  ''');
                debugPrint("Access token injected into WebView: $escapedToken");
              } else {
                debugPrint("No access token to inject.");
              }
            },

            // Log console messages from the WebView
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint("WebView Console: ${consoleMessage.message}");
              // Parse acknowledgment messages if any
              if (consoleMessage.message.contains('acknowledgment')) {
                try {
                  final data = jsonDecode(consoleMessage.message);
                  if (data['key'] == 'acknowledgment') {
                    debugPrint("Acknowledgment received from WebView: ${data['message']}");
                    debugPrint("Value received: ${data['receivedValue']}");
                  }
                } catch (e) {
                  debugPrint("Error parsing acknowledgment message: $e");
                }
              }
            },
          ),
          if (progress < 1.0) // Show loading indicator until progress completes
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
        ],
      ),
    );
  }

  // Build the body content based on the selected tab
  Widget _buildBodyContent() {
    switch (currentPageIndex) {
      case 0: // Home page
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/Home.png',
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 1: // Goals page
      case 2: // Meditations page
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
          child: Image.asset(
            'assets/images/Discover.png',
            fit: BoxFit.cover,
          ),
        );
      case 3: // Videos page
      default:
        return const Center(
          child: Text('Videos page'),
        );
    }
  }

  // Main UI with bottom navigation bar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _handleNavigation,
        indicatorColor: Colors.purple,
        selectedIndex: currentPageIndex,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home, color: Colors.white),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.golf_course_sharp, color: Colors.white),
            icon: Icon(Icons.golf_course_sharp),
            label: 'Goals',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.medical_information_outlined, color: Colors.white),
            icon: Icon(Icons.medical_information_outlined),
            label: 'Meditations',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.video_collection_sharp, color: Colors.white),
            icon: Icon(Icons.video_collection_sharp),
            label: 'Videos',
          ),
        ],
      ),
      body: showWebView ? _buildWebView() : _buildBodyContent(),
    );
  }
}

// Extension for CookieManager to clear cookies
extension on CookieManager {
  void clearCookies() {}
}