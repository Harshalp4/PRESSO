import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';

class RiderShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RiderShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: PressoTokens.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: PressoBreakpoints.bodyMaxWidth(context)),
              child: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: PressoTokens.primary,
            unselectedItemColor: PressoTokens.textHint,
            selectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline, size: 22),
                activeIcon: Icon(Icons.work, size: 22),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history, size: 22),
                activeIcon: Icon(Icons.history, size: 22),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined, size: 22),
                activeIcon: Icon(Icons.account_balance_wallet, size: 22),
                label: 'Earnings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 22),
                activeIcon: Icon(Icons.person, size: 22),
                label: 'Account',
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}
