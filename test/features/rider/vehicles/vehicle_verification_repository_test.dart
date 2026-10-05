import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_verification_repository_impl.dart';
import 'package:delivery_boy/features/rider/vehicles/service/rider_vehicle_photo_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vehicle_test_support.dart';

/// Answers every request with [respond], recording what was sent.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await requestStream?.drain<void>();
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late Directory dir;
  late String photo;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('vehicle_repo_');
    photo = await tempJpeg(dir, 'rear');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  (VehicleVerificationRepositoryImpl, _FakeAdapter) build(
    ResponseBody Function(RequestOptions) respond,
  ) {
    final adapter = _FakeAdapter(respond);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = adapter;
    return (
      VehicleVerificationRepositoryImpl(RiderVehiclePhotoApiService(dio)),
      adapter,
    );
  }

  final profileBody = {
    'success': true,
    'data': riderMeData((json) {
      (json['vehicle'] as Map)['photos'] = {'front': null, 'back': backUrl};
    }),
  };

  test('uploads the rear photo as "back", in a multipart "photo" field',
      () async {
    final (repo, adapter) = build((_) => _json(200, profileBody));

    final result = await repo.uploadPhoto(VehicleCaptureType.rear, photo);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/v1/rider/me/vehicle-photos/back');
    expect((request.data as FormData).files.single.key, 'photo');
    final profile = result.getOrElse(() => null);
    expect(profile?.vehiclePhotos, {'back': backUrl});
  });

  test('reports upload progress as a fraction', () async {
    final (repo, _) = build((_) => _json(200, profileBody));
    final fractions = <double>[];

    await repo.uploadPhoto(
      VehicleCaptureType.rear,
      photo,
      onProgress: fractions.add,
    );

    expect(fractions, isNotEmpty);
    expect(fractions.last, 1.0);
  });

  test('deletes with DELETE and no body', () async {
    final (repo, adapter) = build((_) => _json(200, profileBody));

    final result = await repo.deletePhoto(VehicleCaptureType.front);

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.uri.path, '/api/v1/rider/me/vehicle-photos/front');
    expect(result.isRight(), isTrue);
  });

  test('never sends a capture the API does not store', () async {
    final (repo, adapter) = build((_) => _json(200, profileBody));

    final result = await repo.uploadPhoto(VehicleCaptureType.leftSide, photo);

    expect(adapter.requests, isEmpty);
    expect(result.isLeft(), isTrue);
  });

  group('a 200 that is not a profile', () {
    for (final (name, body) in [
      ('no data', ResponseBody.fromString('{"success": true}', 200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]})),
      ('an HTML page', ResponseBody.fromString('<html>OK</html>', 200)),
      ('data without an id', _json(200, {'data': {'vehicle': {}}})),
    ]) {
      test('$name: succeeds with no profile, so the caller reloads', () async {
        final (repo, _) = build((_) => body);
        final result = await repo.uploadPhoto(VehicleCaptureType.rear, photo);
        expect(result.isRight(), isTrue);
        expect(result.fold((_) => 'failure', (profile) => profile), isNull);
      });
    }
  });

  group('failures', () {
    Future<Failure> failureFor(ResponseBody Function(RequestOptions) respond) async {
      final (repo, _) = build(respond);
      final result = await repo.uploadPhoto(VehicleCaptureType.rear, photo);
      return result.fold((f) => f, (_) => fail('expected a failure'));
    }

    test('422 shows the server\'s message for the photo', () async {
      final failure = await failureFor((_) => _json(422, {
            'success': false,
            'message': 'Validation failed',
            'errors': {
              'photo': ['The photo must be a file of type: jpeg, png, jpg.'],
            },
          }));
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'The photo must be a file of type: jpeg, png, jpg.');
    });

    test('401 is a session expiry', () async {
      final failure = await failureFor(
          (_) => _json(401, {'success': false, 'message': 'Unauthenticated.'}));
      expect(failure, isA<SessionExpiredFailure>());
      expect(failure.message, contains('session has expired'));
    });

    test('409 explains the conflict without repeating the server body',
        () async {
      final failure = await failureFor((_) => _json(409, {
            'message': 'Plate registered to Kwame Mensah (0244000000)',
          }));
      expect(failure.message, startsWith('Vehicle already registered'));
      expect(failure.message, isNot(contains('Kwame')));
    });

    test('404 never shows Laravel\'s route message', () async {
      final failure = await failureFor((_) => _json(404, {
            'message': 'The route api/v1/rider/me/vehicle-photos/back could '
                'not be found.',
          }));
      expect(failure.message, isNot(contains('route')));
    });

    test('500 hides the exception text', () async {
      final failure = await failureFor((_) => _json(500, {
            'message': 'SQLSTATE[23000]: Integrity constraint violation',
          }));
      expect(failure.message, 'Something went wrong on our end. Please try again '
          'shortly.');
    });

    test('no connection', () async {
      final failure = await failureFor((options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ));
      expect(failure.message, contains("Couldn't reach the server"));
    });

    test('timeout', () async {
      final failure = await failureFor((options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          ));
      expect(failure.message, contains('took too long'));
    });
  });
}
