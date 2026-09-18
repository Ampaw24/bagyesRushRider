import 'package:equatable/equatable.dart';

enum UploadProgress { idle, uploading, done, failed }

/// Client-side state of one document upload, for `DocumentUploadCard`.
class UploadState extends Equatable {
  final UploadProgress progress;
  final String? localPath;
  final String? errorMessage;

  const UploadState({
    this.progress = UploadProgress.idle,
    this.localPath,
    this.errorMessage,
  });

  bool get isDone => progress == UploadProgress.done;

  bool get isUploading => progress == UploadProgress.uploading;

  @override
  List<Object?> get props => [progress, localPath, errorMessage];
}
