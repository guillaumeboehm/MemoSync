import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/home/home.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:flutter_memosync/src/widgets/list_drawer.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:throttling/throttling.dart';
import 'package:universal_platform/universal_platform.dart';

/// Widget displaying the memo list
class MemoList extends StatefulWidget {
  /// Default constructor
  const MemoList({super.key, required this.constraints});

  /// The constraints for the list computed in the page
  final BoxConstraints constraints;

  @override
  State<MemoList> createState() => _MemoListState();
}

class _MemoListState extends State<MemoList>
    with SingleTickerProviderStateMixin {
  final searchQueryNotifier = ValueNotifier<String>('');
  TextEditingController searchController = TextEditingController();
  final searchDebouncer = Debouncing(
    duration: const Duration(milliseconds: 200),
  );
  AnimationController? refreshSpinController;
  final addingMemo = ValueNotifier(false);

  @override
  void initState() {
    refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    super.initState();
  }

  @override
  void dispose() {
    refreshSpinController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: Size(widget.constraints.maxWidth, widget.constraints.maxHeight),
      child: Center(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Visibility(
                        visible: UniversalPlatform.isWeb ||
                            UniversalPlatform.isFuchsia ||
                            UniversalPlatform.isLinux ||
                            UniversalPlatform.isMacOS ||
                            UniversalPlatform.isWindows,
                        child: BlocBuilder<HomeBloc, HomeState>(
                          buildWhen: (previous, current) =>
                              previous.refreshingMemoList !=
                              current.refreshingMemoList,
                          builder: (searchBarContext, state) {
                            refreshSpinController!.forward(from: 0);
                            return AnimatedBuilder(
                              animation: refreshSpinController!,
                              builder: (BuildContext animContext, _) {
                                return Transform.rotate(
                                  angle: state.refreshingMemoList
                                      ? refreshSpinController!.value * 5
                                      : 0,
                                  child: IconButton(
                                    onPressed: state.refreshingMemoList
                                        ? null
                                        : () {
                                            context
                                                .read<HomeBloc>()
                                                .add(const RefreshMemoList());
                                            Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () async {
                                                if (!mounted) return;
                                                await context
                                                    .read<HomeBloc>()
                                                    .stream
                                                    .firstWhere(
                                                      (bloc) =>
                                                          // ignore: lines_longer_than_80_chars
                                                          bloc.refreshingMemoList ==
                                                          false,
                                                    );
                                                // guard clause above
                                                // ignore: use_build_context_synchronously
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Memo list refreshed',
                                                    ),
                                                    duration:
                                                        Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                    ),
                                    iconSize: 30,
                                    padding: EdgeInsets.zero,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            searchDebouncer.debounce(() {
                              searchQueryNotifier.value = value;
                            });
                          },
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Search',
                            hintText: 'Search',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              padding: const EdgeInsets.only(right: 15),
                              onPressed: () {
                                searchController.clear();
                                searchQueryNotifier.value = '';
                              },
                              icon: const Icon(Icons.close),
                              hoverColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () {
                      Logger.info('PullToRefresh');
                      context.read<HomeBloc>().add(const RefreshMemoList());
                      return Future.delayed(
                        const Duration(milliseconds: 100),
                        () async {
                          if (!mounted) return;
                          await context.read<HomeBloc>().stream.firstWhere(
                                (element) =>
                                    element.refreshingMemoList == false,
                              );
                          // guard close above
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Memo list refreshed'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                    child: ValueListenableBuilder(
                      // Listen for memo changes
                      valueListenable: Storage.memosStorageStream(),
                      builder: (listContext, List<MemoObject> memoList, _) {
                        return ValueListenableBuilder(
                          // Listen for search query changes
                          valueListenable: searchQueryNotifier,
                          builder: (context, String? query, _) {
                            // Filter items with search query
                            final filterdItems = Fuzzy(
                              memoList.map((value) => value.title).toList(),
                              options: FuzzyOptions<dynamic>(
                                shouldNormalize: true,
                              ),
                            )
                                .search(query ?? '')
                                .map<String>(
                                  (result) => result.item.toString(),
                                )
                                .toList();

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: filterdItems.length,
                              itemBuilder: (itemContext, index) {
                                return listTile(filterdItems[index]);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            ListDrawer(width: widget.constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  Widget listTile(String? memoTitle) {
    return ListTile(
      title: Text(
        memoTitle ?? '',
      ),
      dense: true,
      hoverColor: Colors.blueGrey,
      onTap: () {
        context.read<HomeBloc>().add(
              ChangeCurrentMemo(
                currentMemo: memoTitle ?? '',
              ),
            );
      },
      trailing: IconButton(
        onPressed: () {
          showDialog<AlertDialog>(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext diagContext) {
              final processing = ValueNotifier<bool>(false);
              return ValueListenableBuilder(
                valueListenable: processing,
                builder: (
                  processingContext,
                  isProcessing,
                  _,
                ) {
                  return (isProcessing as bool? ?? false)
                      ? const AlertDialog(
                          title: Text('Deletion'),
                          content: SizedBox(
                            height: 32,
                            width: 32,
                            child: Center(
                              child:
                                  // ignore: lines_longer_than_80_chars
                                  CircularProgressIndicator(),
                            ),
                          ),
                        )
                      : AlertDialog(
                          title: const Text('Deletion'),
                          content: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: '''Are you sure you want to''',
                                ),
                                TextSpan(
                                  text: ''' delete $memoTitle''',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                const TextSpan(
                                  text: ''',\nthis action is irreversible.''',
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  diagContext,
                                ).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (memoTitle != null) {
                                  context.read<HomeBloc>().add(
                                        DeleteMemo(
                                          memoTitle,
                                          diagContext,
                                        ),
                                      );
                                  processing.value = true;
                                } else {
                                  Navigator.of(
                                    diagContext,
                                  ).pop();
                                }
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                },
              );
            },
          );
        },
        icon: const Icon(Icons.delete),
        iconSize: 20,
      ),
    );
  }
}
