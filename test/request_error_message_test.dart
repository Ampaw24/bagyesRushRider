import 'dart:io';

import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final _options = RequestOptions(path: '/login');

DioException _badResponse(int status, dynamic body) => DioException(
      requestOptions: _options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: _options,
        statusCode: status,
        data: body,
      ),
    );

const _nginx502 = '<html><head><title>502 Bad Gateway</title></head></html>';

void main() {
  group('dioErrorMessage', () {
    test("prefers the server's field message", () {
      final e = _badResponse(422, {
        'success': false,
        'message': 'Validation failed',
        'errors': {
          'phone': ['The phone has already been taken.'],
        },
      });

      expect(dioErrorMessage(e), 'The phone has already been taken.');
    });

    test('replaces Dio developer text when the server is unreachable', () {
      final e = DioException.connectionError(
        requestOptions: _options,
        reason: "Failed host lookup: 'api.bagyesrushdelivery.com'",
      );

      final message = dioErrorMessage(e);
      expect(message, contains("Couldn't reach the server"));
      expect(message, isNot(contains('connection errored')));
      expect(message, isNot(contains('library')));
    });

    test('treats a SocketException surfaced as unknown as unreachable', () {
      final e = DioException(
        requestOptions: _options,
        error: const SocketException('Connection reset by peer'),
      );

      expect(dioErrorMessage(e), contains("Couldn't reach the server"));
    });

    test('explains timeouts', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = DioException(requestOptions: _options, type: type);
        expect(dioErrorMessage(e), contains('too long'), reason: '$type');
      }
    });

    test('handles an HTML error page without throwing', () {
      expect(
        dioErrorMessage(_badResponse(502, _nginx502)),
        contains('on our end'),
      );
    });

    test('explains an oversized upload rejected by the proxy', () {
      expect(
        dioErrorMessage(_badResponse(413, '<html>Request Entity Too Large')),
        contains('too large'),
      );
    });

    test('uses the fallback when nothing more specific applies', () {
      final e = DioException(requestOptions: _options, error: 'boom');

      expect(
        dioErrorMessage(e, fallback: 'Failed to load vehicle catalogue'),
        'Failed to load vehicle catalogue',
      );
      expect(dioErrorMessage(e), 'Something went wrong. Please try again.');
    });

    test('ignores a blank server message', () {
      final e = _badResponse(500, {'message': '  '});

      expect(dioErrorMessage(e), contains('on our end'));
    });
  });

  group('unexpectedErrorMessage', () {
    test('never exposes the underlying error text', () {
      final error = TypeError();

      final message = unexpectedErrorMessage(error, StackTrace.current);
      expect(message, 'Something went wrong. Please try again.');
      expect(message, isNot(contains('TypeError')));
    });
  });
}
