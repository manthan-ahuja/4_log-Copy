import 'package:flutter/material.dart';

import '../widgets/map_section.dart';
import '../widgets/avatar_list.dart';
import '../widgets/card_section.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F9),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 🗺️ MAP takes remaining space
            Expanded(
              child: MapSection(),
            ),

            // 📜 Scrollable bottom content
            SingleChildScrollView(
              child: Column(
                children: const [
                  AvatarList(),
                  CardSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
