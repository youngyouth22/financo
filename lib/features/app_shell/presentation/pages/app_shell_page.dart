import 'package:financo/features/finance/presentation/pages/add_crypto_wallet_page.dart';
import 'package:financo/features/home/presentation/pages/dashboard_page.dart';
import 'package:financo/features/home/presentation/widgets/custom_floating_button.dart';
import 'package:financo/features/home/presentation/widgets/custom_nav_bar.dart';
import 'package:flutter/material.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;
  late PageController _controller;
  List<Widget> get _pages => [
    const DashboardPage(),
    const Center(child: Text('Asset Page')),
    const Center(child: Text('Insight Page')),
    const Center(child: Text('Setting Page')),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: CustomFloatingButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddCryptoWalletPage(),
            ),
          );
        },
        isMenuOpen: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        clipBehavior: Clip.antiAlias,
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        padding: EdgeInsets.zero,
        color: Colors.transparent,
        child: CustomNavBar(
          currentIndex: _currentIndex,
          onItemSelected: (index) {
            setState(() {
              _currentIndex = index;
              animateToPage(index);
            });
          },
        ),
      ),
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
    );
  }
}
