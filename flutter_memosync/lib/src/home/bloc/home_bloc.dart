import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bottom_drawer/bottom_drawer.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_memosync/src/authentication/bloc/authentication_bloc.dart';
import 'package:flutter_memosync/src/home/repositories/memo.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Bloc handling memos
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// Default constructor
  HomeBloc(this.authBloc, this.memoRepository, this.homeContext)
      : super(const HomeState()) {
    on<ChangeCurrentMemo>(_onChangeCurrentMemo);
    on<DeselectCurrentMemo>(_onDeselectCurrentMemo);
    on<ChangeViewPage>(_onChangeViewPage);
    on<RefreshMemoList>(_onRefreshMemoList);
    on<CreateMemo>(_onCreateMemo);
    on<DeleteMemo>(_onDeleteMemo);
    on<MemoChanged>(_onMemoChanged);
    on<SyncMemo>(_onSyncMemo);

    // Refresh memo list on launch
    add(const RefreshMemoList());
  }

  /// Uses the authBloc for authentication
  ///
  /// Needs access to the accessToken and to be able to refresh the token
  /// if necessary
  final AuthenticationBloc authBloc;

  /// Repository for API comunication
  final MemoRepository memoRepository;

  /// Context of the home page
  final BuildContext homeContext;

  /// Changes the currently selected memo
  void _onChangeCurrentMemo(
    ChangeCurrentMemo event,
    Emitter<HomeState> emit,
  ) {
    emit(
      HomeState.currentMemoChanged(
        prevState: state,
        currentMemo: event.currentMemo,
      ),
    );
  }

  /// Deselect the selected memo
  void _onDeselectCurrentMemo(
    DeselectCurrentMemo event,
    Emitter<HomeState> emit,
  ) {
    emit(
      HomeState.currentMemoChanged(
        prevState: state,
        currentMemo: '',
      ),
    );
  }

  /// Change the view on the home page
  ///
  /// In wide screen this dictates if a memo is displayed and if the settings
  /// view is shown.
  /// In smartphone view this acts as pages.
  void _onChangeViewPage(
    ChangeViewPage event,
    Emitter<HomeState> emit,
  ) {
    emit(
      HomeState.viewPageChanged(
        prevState: state,
        viewPage: event.viewPage,
      ),
    );
  }

  /// Ask to refresh the memo list
  ///
  /// Sets [state]'s refreshingMemoList to true while fetching
  /// and sets it back to false afterwards.
  /// The [memoRepository.getAllMemos()] call updates the hive storage
  // ignore: comment_references
  /// which automatically triggers a [ValueListenableBuilder]
  /// to rebuild the list
  Future<void> _onRefreshMemoList(
    RefreshMemoList event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.refreshingMemoList) {
      emit(
        HomeState.memoListRefreshState(
          prevState: state,
          refreshing: true,
        ),
      );
      final sw = Stopwatch();
      const minTime = 100; //in milliseconds

      final memos =
          await memoRepository.getAllMemos(authBloc.state.accessToken ?? '');

      // Quick throttlish timer to make sure
      // it's not going too fast for the state emitter
      if (sw.elapsedMilliseconds < minTime) {
        await Future.delayed(
          Duration(milliseconds: minTime - sw.elapsedMilliseconds),
          () {
            unawaited(Logger.info('BLOC: ${memos.toString()}'));
          },
        );
      }

      emit(
        HomeState.memoListRefreshState(
          prevState: state,
          refreshing: false,
        ),
      );
    }
  }

  /// Delete a memo in the database
  ///
  /// If the deleted memo is the currently selected memo, emits a memo change
  Future<void> _onDeleteMemo(
    DeleteMemo event,
    Emitter<HomeState> emit,
  ) async {
    await memoRepository
        .deleteMemo(
      authBloc.state.accessToken ?? '',
      memoTitle: event.memoTitle,
    )
        .then(
      (res) {
        if (res) {
          if (event.memoTitle == state.currentMemo) {
            emit(
              HomeState.currentMemoChanged(
                prevState: state,
                currentMemo: '',
              ),
            );
          }
          ScaffoldMessenger.of(homeContext).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade400,
              content: const Text('Memo deleted'),
            ),
          );
        } else {
          ScaffoldMessenger.of(homeContext).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade400,
              content: const Text('Error while trying to delete the memo.'),
            ),
          );
        }
        Navigator.of(event.diagContext).pop();
      },
    );
  }

  /// Create a memo in the database
  Future<void> _onCreateMemo(
    CreateMemo event,
    Emitter<HomeState> emit,
  ) async {
    await memoRepository
        .createMemo(
      authBloc.state.accessToken ?? '',
      memoTitle: event.memoTitle,
    )
        .then(
      (res) {
        if (res != null) {
          //Error
          if (res['code'] == 'MemoAlreadyExists') {
            ScaffoldMessenger.of(homeContext).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade400,
                content: const Text('A memo with this title already exists.'),
              ),
            );
            add(const RefreshMemoList());
          } else if (res['code'] == 'EmptyTitle') {
            ScaffoldMessenger.of(homeContext).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade400,
                content: const Text('Enter a title for the memo.'),
              ),
            );
          } else if (res['code'] == 'InternalError') {
            ScaffoldMessenger.of(homeContext).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade400,
                content:
                    const Text('Something went wrong while creating the memo.'),
              ),
            );
          }
        } else {
          //Success
          ScaffoldMessenger.of(homeContext).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade400,
              content: const Text('Memo created.'),
            ),
          );
          add(const RefreshMemoList());
          event.addingMemo.value = false;
          event.drawerController.close();
        }
      },
    );
  }

  /// Called when the user modifies the memo localy
  Future<void> _onMemoChanged(
    MemoChanged event,
    Emitter<HomeState> emit,
  ) async {
    final oldMemo = Storage.getMemo(memo: event.memoTitle);

    final modifications = patchToText(
      DiffMatchPatch().patch(
        oldMemo?.lastSynchedText ?? '',
        event.memoContent,
      ),
    );
    // unawaited(Logger.info(modifications));

    if (oldMemo?.patches != modifications) {
      oldMemo?.patches = modifications;
      oldMemo?.text = event.memoContent;
      Storage.setMemo(memo: event.memoTitle, obj: oldMemo);
      unawaited(Logger.info('local changes saved'));
    }
  }

  /// Called to synchronize the memo with remote
  Future<void> _onSyncMemo(
    SyncMemo event,
    Emitter<HomeState> emit,
  ) async {
    await memoRepository
        .syncMemo(
      authBloc.state.accessToken ?? '',
      memoTitle: event.memoTitle,
      memoContent: event.memoContent,
      memoVersion: event.memoVersion,
      memoPatches: event.memoPatches,
    )
        .then((res) {
      if (res != null) {
        // an error occured
        ScaffoldMessenger.of(homeContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade400,
            content: Builder(
              builder: (context) {
                switch (res['code']) {
                  case 'NewerVersionExists':
                    return const Text(
                      '''
A newer version of the memo has been merged, verify the memo for any mistakes.''',
                    );
                  case 'MemoDeleted':
                    return const Text(
                      '''This memo has been deleted from an other device.''',
                    );
                  default:
                    return Text("An error occured during sync: ${res['code']}");
                }
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(homeContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade300,
            content: const Text('Memo synced successfully'),
          ),
        );
      }
    });
  }
}
