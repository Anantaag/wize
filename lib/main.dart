import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import 'screens/home_page.dart';
import 'screens/history_page.dart';
import 'screens/community_page.dart';
import 'screens/profile_page.dart';

void main() {
  runApp(WizeApp());
}

class WizeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wize',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: BottomNavBarWrapper(),
    );
  }
}

class BottomNavBarWrapper extends StatefulWidget {
  @override
  _BottomNavBarWrapperState createState() => _BottomNavBarWrapperState();
}

class _BottomNavBarWrapperState extends State<BottomNavBarWrapper> {
  int _selectedIndex = 0;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  StreamSubscription? _sub;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomePage(key: _homePageKey),
      HistoryPage(),
      CommunityPage(),
      ProfilePage(),
    ];

    _handleInitialUri();
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && _isSosLink(uri)) {
        _triggerSosFromLink();
      }
    }, onError: (err) {
      print('URI stream error: $err');
    });
  }

  bool _isSosLink(Uri uri) {
    // Replace with your actual App Link domain and path
    return uri.scheme == 'https' &&
        uri.host.contains('yourdomain.com') &&
        uri.pathSegments.contains('sos');
  }

  void _triggerSosFromLink() {
    _homePageKey.currentState?.sendSosAlert();
    setState(() {
      _selectedIndex = 0;
    });
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null && _isSosLink(uri)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerSosFromLink();
        });
      }
    } on PlatformException catch (e) {
      print('PlatformException: $e');
    } on FormatException catch (e) {
      print('FormatException: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}