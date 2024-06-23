part of 'home_bloc.dart';

/// The [HomeBloc] events
abstract class HomeEvent extends Equatable {
  /// Default constructor
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// [HomeEvent] to change the currently selected memo
class ChangeCurrentMemo extends HomeEvent {
  /// Constructor
  const ChangeCurrentMemo({required this.currentMemo});

  /// The currently selected memo
  final String currentMemo;

  @override
  List<Object> get props => [
        currentMemo,
      ];
}

/// [HomeEvent] to deselect the selected memo
class DeselectCurrentMemo extends HomeEvent {
  /// constructor
  const DeselectCurrentMemo();
}

/// [HomeEvent] to change the current view
class ChangeViewPage extends HomeEvent {
  /// Constructor
  const ChangeViewPage({required this.viewPage});

  /// The wanted view
  final ViewPage viewPage;

  @override
  List<Object> get props => [
        viewPage,
      ];
}

/// [HomeEvent] to fetch new memo for the list
class RefreshMemoList extends HomeEvent {
  /// Constructor
  const RefreshMemoList();
}

/// [HomeEvent] to fetch new memo for the list
class UpdateMemo extends HomeEvent {
  /// Constructor
  const UpdateMemo(this.memoTitle);

  /// Title of the memo to modify
  final String memoTitle;

  @override
  List<Object> get props => [
        memoTitle,
      ];
}

/// [HomeEvent] to fetch new memo for the list
class CreateMemo extends HomeEvent {
  /// Constructor
  const CreateMemo(this.memoTitle, this.addingMemo, this.drawerController);

  /// Title of the memo to delete
  final String memoTitle;

  /// ValueNotifire used to manage the list barrier
  final ValueNotifier<bool> addingMemo;

  /// Controller to close the drawer
  final BottomDrawerController drawerController;

  @override
  List<Object> get props => [
        memoTitle,
        addingMemo,
        drawerController,
      ];
}

/// [HomeEvent] to fetch new memo for the list
class DeleteMemo extends HomeEvent {
  /// Constructor
  const DeleteMemo(this.memoTitle, this.diagContext);

  /// Title of the memo to delete
  final String memoTitle;

  /// The context of the confirmation dialog
  final BuildContext diagContext;

  @override
  List<Object> get props => [
        memoTitle,
        diagContext,
      ];
}

/// [HomeEvent] called when the memo is modified by the user
class MemoChanged extends HomeEvent {
  /// Constructor
  const MemoChanged(this.memoTitle, this.memoContent);

  /// Title of the memo to delete
  final String memoTitle;

  /// Content of the modified memo
  final String memoContent;

  @override
  List<Object> get props => [
        memoTitle,
        memoContent,
      ];
}

/// [HomeEvent] called when the memo is modified by the user
class SyncMemo extends HomeEvent {
  /// Constructor
  const SyncMemo(
    this.memoTitle,
    this.memoContent,
    this.memoVersion,
    this.memoPatches,
  );

  /// Title of the memo to delete
  final String memoTitle;

  /// Content of the modified memo
  final String memoContent;

  /// New version of the modified memo
  final int memoVersion;

  /// Last patches of the modified memo
  final String memoPatches;

  @override
  List<Object> get props => [
        memoTitle,
        memoContent,
        memoVersion,
        memoPatches,
      ];
}
