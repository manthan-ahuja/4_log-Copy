import 'package:flutter/material.dart';

final List<String> images = [
  'assets/images/user1.png',
  'assets/images/2.png',
  'assets/images/3.png',
  'assets/images/4.png',
  'assets/images/5.png',
  'assets/images/6.png',
  'assets/images/7.png',
];

class AvatarList extends StatelessWidget {
  const AvatarList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage(images[index]),
            ),
          );
        },
      ),
    );
  }
}
