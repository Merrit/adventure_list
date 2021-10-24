import 'package:device_type/device_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../application/home/cubit/home_cubit.dart';
import '../../../domain/domain.dart';
import '../../styles.dart';

class ListNameTile extends StatefulWidget {
  final TodoList list;

  const ListNameTile({
    Key? key,
    required this.list,
  }) : super(key: key);

  @override
  State<ListNameTile> createState() => _ListNameTileState();
}

class _ListNameTileState extends State<ListNameTile> {
  bool mouseIsOver = false;

  @override
  Widget build(BuildContext context) {
    final bool _isLargeFormFactor = Device.isLargeFormFactor(context);

    return Slidable(
      actionPane: const SlidableDrawerActionPane(),
      actionExtentRatio: 0.20,
      secondaryActions: [
        IconSlideAction(
          color: Colors.blueGrey,
          icon: Icons.settings,
          onTap: () => _showListConfigureDialog(),
        ),
      ],
      child: MouseRegion(
        onEnter: (event) => setState(() => mouseIsOver = true),
        onExit: (event) => setState(() => mouseIsOver = false),
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final Color? _tileColor = (state.activeList?.id == widget.list.id)
                ? Colors.grey[800]
                : null;

            final Widget _title = Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: _isLargeFormFactor ? 14 : 0,
                ),
                child: Text(widget.list.name),
              ),
            );

            final Widget _listSettingsButton = IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: mouseIsOver ? Colors.grey : Colors.transparent,
              ),
              // hoverColor: Colors.transparent,
              onPressed: () => _showListConfigureDialog(),
            );

            return ListTile(
              tileColor: _tileColor,
              title: _title,
              onTap: () {
                homeCubit.loadList(widget.list);
                if (!Device.isLargeFormFactor(context)) Navigator.pop(context);
              },
              onLongPress: () {
                // Rearrange order.
              },
              trailing: _listSettingsButton,
            );
          },
        ),
      ),
    );
  }

  Future<void> _showListConfigureDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _ConfigureListDialog(list: widget.list),
    );
  }
}

class _ConfigureListDialog extends StatelessWidget {
  final TodoList list;

  const _ConfigureListDialog({
    Key? key,
    required this.list,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('List settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Divider(),
          Text('Name'),
          Text('Color'),
          Text('Reminder'),
        ],
      ),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () async {
                await showDialog<bool>(
                  context: context,
                  builder: (context) => _ConfirmDeleteDialog(list: list),
                );
              },
              child: const Text('Delete'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(primary: Colors.grey[700]),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                primary: Colors.green[700],
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  final TodoList list;

  const _ConfirmDeleteDialog({
    Key? key,
    required this.list,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'DELETE LIST',
        style: TextStyle(color: CustomColors.warningColor),
      ),
      content: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'This will delete '),
            TextSpan(
              text: list.name,
              style: const TextStyle(color: CustomColors.accentColor),
            ),
            const TextSpan(text: ' permanently.\n'),
            const TextSpan(text: '\n'),
            const TextSpan(text: 'Are you sure?'),
          ],
        ),
      ),
      actions: [
        BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return TextButton(
              onPressed: () async {
                await homeCubit.deleteList(list);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: CustomColors.warningColor),
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}
