import 'dart:async';
import 'dart:convert';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/memo.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:validators/validators.dart';

/// Repository used to handle memo database comunication.
class MemoRepository {
  final _baseUri = Uri(
    scheme: 'https',
    host: dotenv.get('API_URI'),
  );
  final _dio = Dio();
  static Options _baseOptions(String accessToken) {
    return Options(
      headers: <String, dynamic>{'Authorization': 'Bearer $accessToken'},
    );
  }

  /// Create the new memo with title [memoTitle] if it doesn't already exist
  Future<Map<String, dynamic>?> createMemo(
    String accessToken, {
    required String memoTitle,
  }) async {
    late final Map<String, dynamic> res;
    if (memoTitle != '') {
      res = await _dioCall<String>(
        () => _dio.postUri<String>(
          _baseUri.replace(
            path: 'newMemo',
          ),
          data: {
            'memoTitle': memoTitle,
          },
          options: _baseOptions(accessToken),
        ),
      );
    } else {
      return {'code': 'EmptyTitle'};
    }

    // Save the new memos
    if (res.containsKey('success')) {
      Storage.setMemo(
        memo: memoTitle,
        obj: MemoObject()..title = memoTitle,
      );
      return null;
    } else {
      return res['error'] as Map<String, dynamic>;
    }
  }

  /// Fetches all the memos based on the current cache
  Future<Map<String, dynamic>> getAllMemos(String accessToken) async {
    // Fetch the metadata all all memos to know which memos to fetch
    final metaDataRes = await _dioCall<String>(
      () => _dio.getUri<String>(
        _baseUri.replace(
          path: 'getAllMemosMetadata',
          queryParameters: <String, dynamic>{},
        ),
        options: _baseOptions(accessToken),
      ),
    );
    // If everything went smooth determine which memos to fetch and remove
    if (metaDataRes.containsKey('success')) {
      final memos = metaDataRes['success'] as List;
      final memosToFetch = <String>[];
      final memosToRemove = Storage.getMemos();

      for (var memo in memos) {
        memo = memo as Map<String, dynamic>;
        final cachedMemo = Storage.getMemo(memo: memo['title']);

        if (cachedMemo != null) {
          memosToRemove.remove(memo['title']);
        }
        if (cachedMemo == null ||
            cachedMemo.version < (memo['version'] as int)) {
          memosToFetch.add(memo['title'] as String);
        }
      }

      // Remove memos not in the database anymore
      for (final memo in memosToRemove.keys) {
        Storage.removeMemo(memo: memo);
      }

      // Fetch the new memos
      final memosRes = await _dioCall<String>(
        () => _dio.getUri<String>(
          _baseUri.replace(
            path: 'getMemos',
            queryParameters: <String, dynamic>{'memos': memosToFetch},
          ),
          options: _baseOptions(accessToken),
        ),
      );

      // Save the new memos
      if (memosRes.containsKey('success')) {
        for (var newMemo in memosRes['success'] as List) {
          newMemo = newMemo as Map<String, dynamic>;
          final memo = Storage.getMemo(memo: newMemo['title']) ?? MemoObject()
            ..title = newMemo['title'] as String
            ..text = newMemo['text'] as String
            ..lastSynchedText = newMemo['text'] as String
            ..version = newMemo['version'] as int
            ..patches = '';
          Storage.setMemo(memo: memo.title, obj: memo);
        }
      }

      return memosRes..addAll({'removedMemos': memosToRemove.keys.toList()});
    } else {
      return metaDataRes;
    }
  }

  /// Fetches the memo [memoTitle] if there is a new version
  Future<Map<String, dynamic>?> getMemo(
    String accessToken, {
    required String memoTitle,
    int? memoVersion,
  }) async {
    // Fetch the memo if there is a new version
    final res = await _dioCall<String>(
      () => _dio.postUri<String>(
        _baseUri.replace(
          path: 'getMemo',
        ),
        data: {
          'memoTitle': memoTitle,
          'version': memoVersion,
        },
        options: _baseOptions(accessToken),
      ),
    );

    // Save the new memos
    if (res.containsKey('success') &&
        (memoVersion == null ||
            (res['success'] as Map<String, dynamic>)['version'] as int >
                memoVersion)) {
      final newMemo = res['success'] as Map<String, dynamic>;

      final memo = Storage.getMemo(memo: newMemo['title']) ?? MemoObject()
        ..title = newMemo['title'] as String
        ..text = newMemo['text'] as String
        ..lastSynchedText = newMemo['text'] as String
        ..version = newMemo['version'] as int
        ..patches = '';
      Storage.setMemo(memo: memo.title, obj: memo);
      return newMemo;
    }
    return null;
  }

  /// Updates the memo or return the new version if there is one
  Future<Map<String, dynamic>?> syncMemo(
    String accessToken, {
    required String memoTitle,
    required String memoContent,
    required int memoVersion,
    required String memoPatches,
  }) async {
    unawaited(Logger.info('Trying to sync version $memoVersion'));
    final res = await _dioCall<String>(
      () => _dio.postUri<String>(
        _baseUri.replace(
          path: 'updateMemo',
        ),
        data: {
          'memoTitle': memoTitle,
          'memoTxt': memoContent,
          'currentVersion': memoVersion,
        },
        options: _baseOptions(accessToken),
      ),
    );

    // The new memo has been updated
    if (res.containsKey('success')) {
      unawaited(Logger.info('Memo synched to version $memoVersion'));
      final memo = Storage.getMemo(memo: memoTitle) ?? MemoObject()
        ..title = memoTitle
        ..text = memoContent
        ..lastSynchedText = memoContent
        ..version = memoVersion
        ..patches = '';
      Storage.setMemo(memo: memo.title, obj: memo);
      return null; // return null to say nothing needs to change
    }
    // The remote memo is probably newer than the local one
    else {
      final err = res['error'] as Map<String, dynamic>;
      if (err['code'] == 'NewerVersionExists') {
        //A newer version exists on remote
        final newMemo = err['memo'] as Map<String, dynamic>;
        unawaited(Logger.info('Newer version ${newMemo['version']} exists'));
        final prevPatches = patchFromText(memoPatches);
        final mergedTxt = _mergeMemos(
          remoteMemo: newMemo['text'] as String,
          patches: prevPatches,
        );
        final newPatches = <Patch>[];
        for (var i = 0; i < prevPatches.length; ++i) {
          if ((mergedTxt[1] as List<bool>).elementAt(i)) {
            newPatches.add(prevPatches.elementAt(i));
          }
        }
        final memo = Storage.getMemo(memo: memoTitle) ?? MemoObject()
          ..title = memoTitle
          ..text = mergedTxt[0] as String
          ..lastSynchedText = mergedTxt[0] as String
          ..version = newMemo['version'] as int
          ..patches = patchToText(newPatches);
        Storage.setMemo(memo: memo.title, obj: memo);
      } else if (err['code'] == 'MemoDeleted') {
        //The remote has been deleted
        unawaited(
          Logger.info('$memoTitle deleted from remote, deleting locally.'),
        );
        Storage.removeMemo(memo: memoTitle);
      }
      return err;
    }
  }

  /// Deletes [memoTitle] if it exists
  Future<bool> deleteMemo(
    String accessToken, {
    required String memoTitle,
  }) async {
    final res = await _dioCall<String>(
      () => _dio.deleteUri<String>(
        _baseUri.replace(
          path: 'deleteMemo',
        ),
        data: {
          'memoTitle': memoTitle,
        },
        options: _baseOptions(accessToken),
      ),
    );

    // The new memo has been deleted
    if (res.containsKey('success')) {
      Storage.removeMemo(memo: memoTitle);
      return true;
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>> _dioCall<T>(
    Future<Response<T>> Function() fetch,
    // Map<String, dynamic> result,
  ) async {
    final result = <String, dynamic>{};
    try {
      final response = await fetch();
      unawaited(Logger.info(response.data.toString()));
      if (response.data != null && isJSON(response.data)) {
        result['success'] = jsonDecode(response.data! as String);
      } else {
        result['error'] = {'code': 'ResponseNotAJSON'};
      }
    } on DioError catch (e) {
      if (e.response?.data != null) {
        unawaited(Logger.error(e.response?.data.toString()));
        result['error'] = jsonDecode(e.response?.data as String);
      } else {
        unawaited(Logger.errorFromException(e));
        result['error'] = {'code': 'ServerUnreachable'};
      }
    }
    return result;
  }

  // TODO(me): get rid of it
  List<dynamic> _mergeMemos({
    required String remoteMemo,
    required List<Patch> patches,
  }) {
    final patched = patchApply(patches, remoteMemo);
    Logger.info(patched.toString());
    return patched;
  }
}
