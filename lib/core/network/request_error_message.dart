/// Rider-facing messages for failed requests.
///
/// Repositories hand these to the UI, which shows them verbatim in error
/// dialogs — so they must never be Dio's or Dart's developer text such as
/// "The connection errored: Failed host lookup… This indicates an error which
/// most likely cannot be solved by the library".
library;

import 'dart:io';

import 'package:dio/dio.dart';

import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';

const _unreachable =
    "Couldn't reach the server. Check your internet connection and try again.";
const _timedOut = 'The server took too long to respond. Please try again.';
const _generic = 'Something went wrong. Please try again.';

/// The server's own message when the response carries one, otherwise plain
/// language for what went wrong.
///
/// [fallback] replaces the generic text for failures that have no more
/// specific explanation, e.g. "Failed to load vehicle catalogue".
///
/// Nothing is lost for debugging: `RiderDioInterceptor` already logs every
/// [DioException] in full.
String dioErrorMessage(DioException e, {String fallback = _generic}) {
  final fromServer = apiMessageFrom(e.response?.data);
  if (fromServer != null && fromServer.trim().isNotEmpty) return fromServer;

  switch (e.type) {
    case DioExceptionType.connectionError:
      return _unreachable;
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return _timedOut;
    case DioExceptionType.badCertificate:
      return "Couldn't connect securely to the server. Please try again later.";
    case DioExceptionType.cancel:
      return 'The request was cancelled.';
    case DioExceptionType.badResponse:
      return _statusMessage(e.response?.statusCode) ?? fallback;
    case DioExceptionType.unknown:
      // Some platforms surface a dropped connection here rather than as
      // connectionError.
      if (e.error is SocketException) return _unreachable;
      return fallback;
  }
}

/// For a response with no usable body — typically a proxy's HTML error page.
String? _statusMessage(int? status) {
  if (status == null) return null;
  if (status >= 500) {
    return 'Something went wrong on our end. Please try again shortly.';
  }
  switch (status) {
    case 401:
      return 'Your session has expired. Please sign in again.';
    case 403:
      return "You don't have permission to do that.";
    case 404:
      return "We couldn't find what you were looking for.";
    case 413:
      return 'That file is too large to upload. Please choose a smaller one.';
    case 429:
      return 'Too many attempts. Please wait a moment and try again.';
  }
  return null;
}

/// For a non-network failure while handling a response — almost always a
/// payload in an unexpected shape.
///
/// Logs [error], whose text ("type 'Null' is not a subtype of…") means
/// nothing to the rider, and returns a generic message in its place.
String unexpectedErrorMessage(
  Object error,
  StackTrace stackTrace, {
  String fallback = _generic,
}) {
  appLogger.e(
    'Unexpected error handling a response',
    error: error,
    stackTrace: stackTrace,
  );
  return fallback;
}
