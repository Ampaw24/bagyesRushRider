import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/errors/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef DataMap = Map<String, dynamic>;
