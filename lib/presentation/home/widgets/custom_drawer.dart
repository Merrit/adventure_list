import 'package:device_type/device_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/home/cubit/home_cubit.dart';
import '../home.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (!state.drawerIsVisible) return const SizedBox();

        final bool _isLargeFormFactor = Device.isLargeFormFactor(context);

        final Widget _closeDrawerButton = _isLargeFormFactor
            ? const SizedBox()
            : Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.menu),
                ),
              );

        final List<Widget> _listNameTiles = state.todoLists
            .map((list) => ListNameTile(
                  list: list,
                ))
            .toList();

        return Expanded(
          child: ListView(
            children: [
              _closeDrawerButton,
              const NewListButton(),
              ..._listNameTiles,
            ],
          ),
        );
      },
    );
  }
}

class NewListButton extends StatelessWidget {
  const NewListButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('New List'),
          onPressed: () => _showNewListDialog(context),
        ),
      ),
    );
  }

  Future<void> _showNewListDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New list name',
            ),
            onSubmitted: (value) => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    final name = controller.value.text;
    if (name == '') return;
    context.read<HomeCubit>().createList(name);
  }
}
