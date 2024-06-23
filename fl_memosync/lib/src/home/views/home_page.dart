import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memosync/app.dart' show App;
import 'package:memosync/src/home/home.dart';
import 'package:memosync/src/home/views/home_scaffold.dart';
import 'package:memosync/src/home/views/memo.dart';
import 'package:memosync/src/home/views/memo_settings.dart';
import 'package:memosync/src/services/logger.dart';
import 'package:memosync/src/services/storage/storage.dart';

/// Widget containing the memo list, memo view and memo settings
class HomePage extends StatelessWidget {
  /// Default constructor
  const HomePage({super.key});

  /// Generic route used to instanciate [HomePage]
  static MaterialPageRoute<HomePage> route() =>
      MaterialPageRoute<HomePage>(builder: (context) => const HomePage());

  @override
  Widget build(BuildContext context) {
    Logger.info('Building home page.');
    return ValueListenableBuilder(
        valueListenable: Storage.settingsStorageStream(),
        builder: (context, value, child) {
          return HomeScaffold(
            builder: (constraints) {
              return BlocBuilder<HomeBloc, HomeState>(
                buildWhen: (previous, current) =>
                    previous.viewPage != current.viewPage,
                builder: (context, state) {
                  final wideScreen = constraints.maxWidth >= App.maxWidth;
                  const spacePartition = [0.2, 0.4];
                  final listMinWidth = (wideScreen
                              ? (constraints.maxWidth * spacePartition.first)
                                  .clamp(250, 400)
                              : constraints.maxWidth)
                          .toDouble(),
                      memoMinWidth = constraints.maxWidth,
                      settingsMinWidth = (wideScreen
                              ? (constraints.maxWidth * spacePartition.last)
                                  .clamp(250, 400)
                              : constraints.maxWidth)
                          .toDouble();

                  return Row(
                    children: [
                      Visibility(
                        visible:
                            wideScreen || (state.viewPage == ViewPage.list),
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: listMinWidth,
                          ),
                          child: MemoList(
                            constraints: BoxConstraints(maxWidth: listMinWidth),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            wideScreen || (state.viewPage == ViewPage.memo),
                        child: Expanded(
                          flex: 2,
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: memoMinWidth,
                            ),
                            color: Colors.black12,
                            child: const MemoView(),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: state.viewPage == ViewPage.settings,
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: settingsMinWidth,
                          ),
                          child: SettingsView(
                            constraints: BoxConstraints(
                              maxWidth: settingsMinWidth,
                            ),
                            isWide: wideScreen,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        });
  }
}
