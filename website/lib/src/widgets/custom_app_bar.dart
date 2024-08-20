import 'package:flutter/material.dart';
import 'package:website/src/pages/home_page.dart';

import '../pages/privacy_policy.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final preferredSize = const Size.fromHeight(kToolbarHeight);

  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextButton(
        onPressed: () => Navigator.pushReplacementNamed(
          context,
          HomePage.routeName,
        ),
        child: const Text(
          'Adventure List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            PrivacyPolicyPage.routeName,
          ),
          child: const Text('Privacy Policy'),
        ),
      ],
    );
  }
}
