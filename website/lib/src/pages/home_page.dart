import 'package:flutter/material.dart';

import '../widgets/custom_app_bar.dart';

class HomePage extends StatelessWidget {
  static const routeName = '/';

  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(),
    );
  }
}
