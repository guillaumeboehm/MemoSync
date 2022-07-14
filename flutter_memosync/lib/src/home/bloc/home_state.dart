part of 'home_bloc.dart';

/// Lists the possible views
enum ViewPage {
  /// Displays only the memo list
  list,

  /// Displays the selected memo
  memo,

  /// Displays the settings for the selected memo
  settings,
}

/// [HomeBloc] state
class HomeState extends Equatable {
  /// Default constructor
  const HomeState({
    this.currentMemo = '',
    this.viewPage = ViewPage.list,
    this.refreshingMemoList = false,
  });

  factory HomeState._fromState({
    required HomeState prevState,
    String? currentMemo,
    ViewPage? viewPage,
    bool? refreshingMemoList,
  }) {
    return HomeState(
      currentMemo: currentMemo ?? prevState.currentMemo,
      viewPage: viewPage ?? prevState.viewPage,
      refreshingMemoList: refreshingMemoList ?? prevState.refreshingMemoList,
    );
  }

  /// State constructor to change the selected memo
  ///
  /// Sets [viewPage] to memo if necessary
  /// and [currentMemo] to the selected memo.
  /// If the currentMemo is set to `''` falls back to [ViewPage.list]
  factory HomeState.currentMemoChanged({
    required HomeState prevState,
    required String currentMemo,
  }) {
    return HomeState._fromState(
      prevState: prevState,
      currentMemo: currentMemo,
      viewPage: currentMemo == ''
          ? ViewPage.list
          : (prevState.viewPage == ViewPage.list)
              ? ViewPage.memo
              : prevState.viewPage,
    );
  }

  /// Change the [viewPage]
  factory HomeState.viewPageChanged({
    required HomeState prevState,
    required ViewPage viewPage,
  }) {
    return HomeState._fromState(
      prevState: prevState,
      viewPage: viewPage,
    );
  }

  /// Change whether the list is fetching new memos or not
  factory HomeState.memoListRefreshState({
    required HomeState prevState,
    required bool refreshing,
  }) {
    return HomeState._fromState(
      prevState: prevState,
      refreshingMemoList: refreshing,
    );
  }

  /// The currently selected memo
  final String currentMemo;

  /// The current view
  final ViewPage viewPage;

  /// True if the list if fetching new memos
  final bool refreshingMemoList;

  @override
  List<Object?> get props => [
        currentMemo,
        viewPage,
        refreshingMemoList,
      ];
}
