import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/log.dart';
import '../../session/application/session_controller.dart';
import '../../session/data/session_repository.dart';
import '../../settings/application/settings_controller.dart';
import '../data/upload_repository.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(dioProvider));
});

/// Upload state per session.
class UploadState {
  final Map<String, bool> uploading; // sessionId → isUploading

  const UploadState({this.uploading = const {}});
}

class UploadController extends StateNotifier<UploadState> {
  final UploadRepository _repo;
  final SessionRepository _sessionRepo;
  final String Function() _getBaseUrl;

  UploadController({
    required UploadRepository repo,
    required SessionRepository sessionRepo,
    required String Function() getBaseUrl,
  })  : _repo = repo,
        _sessionRepo = sessionRepo,
        _getBaseUrl = getBaseUrl,
        super(const UploadState());

  Future<void> uploadSession({
    required String sessionId,
    required String dirPath,
  }) async {
    state = UploadState(
      uploading: {...state.uploading, sessionId: true},
    );

    try {
      final success = await _repo.uploadSession(
        sessionId: sessionId,
        dirPath: dirPath,
        baseUrl: _getBaseUrl(),
      );

      await _sessionRepo.markUploaded(
        sessionId,
        error: success ? null : 'Upload failed',
      );
    } catch (e) {
      await _sessionRepo.markUploaded(sessionId, error: e.toString());
      log.e('Upload failed', error: e);
    } finally {
      state = UploadState(
        uploading: {...state.uploading, sessionId: false},
      );
    }
  }
}

final uploadControllerProvider =
    StateNotifierProvider<UploadController, UploadState>((ref) {
  return UploadController(
    repo: ref.watch(uploadRepositoryProvider),
    sessionRepo: ref.watch(sessionRepositoryProvider),
    getBaseUrl: () => ref.read(settingsProvider).serverBaseUrl,
  );
});
