import 'package:device_type/device_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/home/cubit/home_cubit.dart';
import '../pages/home_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  final preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final bool _isLargeFormFactor = Device.isLargeFormFactor(context);

        Widget? _leading() {
          // Use SizedBox instead of null if unauthenticated, so we don't get
          // a back button on the sign-in page.
          if (!state.authenticated) return const SizedBox();
          if (_isLargeFormFactor && state.authenticated) {
            return Padding(
              padding: const EdgeInsets.only(left: 20),
              child: IconButton(
                onPressed: () => homeCubit.toggleDrawer(),
                icon: const Icon(Icons.menu),
              ),
            );
          } else {
            return null;
          }
        }

        final Widget? _title = (state.activeList == null)
            ? null
            : Text(
                state.activeList!.name,
              );

        final List<Widget> _actions = [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: TextButton.icon(
                    onPressed: () {
                      homeCubit.logOut();
                      Navigator.pushReplacementNamed(context, HomePage.id);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ),
              ];
            },
          ),
        ];

        return AppBar(
          leading: _leading(),
          title: _title,
          actions: (state.authenticated) ? _actions : null,
        );
      },
    );
  }
}
