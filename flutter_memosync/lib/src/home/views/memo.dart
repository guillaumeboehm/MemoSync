import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/app.dart';
import 'package:flutter_memosync/src/home/home.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/memo.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:throttling/throttling.dart';

/// Main memo view with the memo editor
class MemoView extends StatefulWidget {
  /// Default constructor
  const MemoView({super.key});

  @override
  State<MemoView> createState() => _MemoViewState();
}

class _MemoViewState extends State<MemoView> {
  final _memoController = TextEditingController();
  final _autoSaveDebouncer = Debouncing();
  final _memoModifiedDebouncer = Debouncing(
    duration: const Duration(milliseconds: 400),
  );
  final _textFocus = FocusNode();
  Map<String, int> cursorPos = {};

  @override
  void dispose() {
    _autoSaveDebouncer.close();
    _memoModifiedDebouncer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) => previous.viewPage != current.viewPage,
      builder: (context, state) {
        return Center(
          // Center avoids the background having a different
          // color when nothing is visible
          child: Visibility(
            visible: state.currentMemo != '',
            child: Stack(
              alignment: Alignment.center,
              children: [
                BlocBuilder<HomeBloc, HomeState>(
                  buildWhen: (previous, current) =>
                      previous.currentMemo != current.currentMemo,
                  builder: (context, state) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 30,
                            width: Size.infinite.width,
                            child: ValueListenableBuilder(
                              // ignore: lines_longer_than_80_chars
                              // TODO(me): Avoid reload when the changes are local
                              valueListenable: Storage.singleMemoStorageStream(
                                state.currentMemo,
                              ),
                              builder: (context, memo, _) {
                                final patches = (memo as MemoObject?)?.patches;
                                final isModified =
                                    patches != null && patches.isNotEmpty;
                                return ColoredBox(
                                  color:
                                      isModified ? Colors.amber : Colors.grey,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          state.currentMemo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Visibility(
                                          visible: isModified,
                                          child: TextButton(
                                            onPressed: () {
                                              final currentText =
                                                  memo?.text ?? '';
                                              final currentVersion =
                                                  (memo?.version ?? 0) + 1;
                                              final currentPatches =
                                                  memo?.patches ?? '';
                                              context.read<HomeBloc>().add(
                                                    SyncMemo(
                                                      state.currentMemo,
                                                      currentText,
                                                      currentVersion,
                                                      currentPatches,
                                                    ),
                                                  );
                                            },
                                            child: const Text('Sync'),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final child = Padding(
                                padding: const EdgeInsets.only(top: 30),
                                child: SingleChildScrollView(
                                  controller: ScrollController(),
                                  padding: const EdgeInsets.all(10),
                                  clipBehavior: Clip.antiAlias,
                                  child: ValueListenableBuilder(
                                    valueListenable:
                                        Storage.singleMemoStorageStream(
                                      state.currentMemo,
                                    ),
                                    builder: (context, memo, widget) {
                                      _memoController.text = memo == null
                                          ? ''
                                          : (memo as MemoObject?)?.text ?? '';
                                      if (cursorPos[state.currentMemo] !=
                                          null) {
                                        _memoController.selection =
                                            TextSelection(
                                          baseOffset: min(
                                            cursorPos[state.currentMemo] ?? 0,
                                            _memoController.text.length,
                                          ),
                                          extentOffset: min(
                                            cursorPos[state.currentMemo] ?? 0,
                                            _memoController.text.length,
                                          ),
                                        );
                                      }
                                      _textFocus.requestFocus();

                                      return TextField(
                                        controller: _memoController,
                                        maxLines: null,
                                        autofocus: true,
                                        focusNode: _textFocus,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                        ),
                                        onTap: () {
                                          cursorPos[state.currentMemo] =
                                              _memoController
                                                  .selection.base.offset;
                                        },
                                        onChanged: (text) {
                                          cursorPos[state.currentMemo] =
                                              _memoController
                                                  .selection.base.offset;
                                          Future<void> changeMemo() async {
                                            context.read<HomeBloc>().add(
                                                  MemoChanged(
                                                    state.currentMemo,
                                                    _memoController.text,
                                                  ),
                                                );
                                          }

                                          if (_memoModifiedDebouncer.isReady) {
                                            // Launch once before the debouncer
                                            changeMemo();
                                            _memoModifiedDebouncer
                                                .debounce(() {});
                                          } else {
                                            _memoModifiedDebouncer.debounce(
                                              changeMemo,
                                            );
                                          }
                                          // if (autoSaveEnabled) {
                                          //   _autoSaveDebouncer.debounce(() {
                                          // TODO(me): auto save
                                          //   });
                                          // }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                              if (constraints.maxWidth < App.maxWidth) {
                                return RefreshIndicator(
                                  onRefresh: () async {
                                    unawaited(Logger.info('refreshing'));
                                    return Future.delayed(
                                      const Duration(seconds: 2),
                                    );
                                  },
                                  child: child,
                                );
                              } else {
                                return child;
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      onPressed: () {
                        context.read<HomeBloc>().add(
                              context.read<HomeBloc>().state.viewPage ==
                                      ViewPage.settings
                                  ? const ChangeViewPage(
                                      viewPage: ViewPage.memo,
                                    )
                                  : const ChangeViewPage(
                                      viewPage: ViewPage.settings,
                                    ),
                            );
                      },
                      tooltip: 'Open settings',
                      child: const Icon(
                        Icons.settings,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
