import 'package:bottom_drawer/bottom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/home/home.dart';

/// Bottom drawer widget used when adding a memo
class ListDrawer extends StatefulWidget {
  /// Default constructor
  const ListDrawer({Key? key, required this.width}) : super(key: key);

  /// Width of the list panel
  final double width;

  @override
  State<ListDrawer> createState() => _ListDrawerState();
}

class _ListDrawerState extends State<ListDrawer> {
  final _addingMemo = ValueNotifier<bool>(false);
  static const _drawerSize = 180.0;
  final _drawerController = BottomDrawerController();
  final _inputController = TextEditingController();
  final _inputFocusController = FocusNode();

  void openDrawer() {
    _inputController.clear();
    _inputFocusController.requestFocus();
    _drawerController.open();
    _addingMemo.value = true;
  }

  void closeDrawer({bool fromDrawer = false}) {
    if (!fromDrawer) _drawerController.close();
    _addingMemo.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _addingMemo,
          builder: (context, value, _) {
            return Stack(
              children: [
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: value ? .5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const ColoredBox(
                      color: Colors.black,
                      child: Center(),
                    ),
                  ),
                ),
                Visibility(
                  visible: value,
                  child: ModalBarrier(
                    onDismiss: closeDrawer,
                  ),
                ),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: FloatingActionButton(
              heroTag: 'bigAddButton',
              onPressed: openDrawer,
              child: const Icon(
                Icons.add,
                size: 40,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ValueListenableBuilder<bool>(
            valueListenable: _addingMemo,
            builder: (context, value, _) {
              return AnimatedOpacity(
                // Bit of a hack to wait for the drawer to close
                opacity: value ? 1 : 0,
                duration:
                    value ? Duration.zero : const Duration(milliseconds: 500),
                child: BottomDrawer(
                  header: Container(),
                  body: SizedBox(
                    height: _drawerSize,
                    width: widget.width,
                    child: ColoredBox(
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 50),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  color: Colors.grey.shade400,
                                ),
                                child: const Divider(
                                  color: Colors.transparent,
                                  height: 5,
                                  thickness: 0,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 15, bottom: 5),
                              child: Text(
                                'Create a new memo',
                                style: TextStyle(fontSize: 17),
                              ),
                            ),
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'New memo title',
                              ),
                              controller: _inputController,
                              focusNode: _inputFocusController,
                              textInputAction: TextInputAction.go,
                              onSubmitted: (value) {
                                context.read<HomeBloc>().add(
                                      CreateMemo(
                                        value,
                                        _addingMemo,
                                        _drawerController,
                                      ),
                                    );
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 5),
                              child: FloatingActionButton.small(
                                heroTag: 'smolAddButton',
                                onPressed: () {
                                  context.read<HomeBloc>().add(
                                        CreateMemo(
                                          _inputController.text,
                                          _addingMemo,
                                          _drawerController,
                                        ),
                                      );
                                },
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  headerHeight: 0,
                  drawerHeight: _drawerSize,
                  controller: _drawerController,
                  followTheBody: false,
                  callback: (status) {
                    if (!status) {
                      closeDrawer(fromDrawer: true);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
