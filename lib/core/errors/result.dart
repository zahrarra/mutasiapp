// lib/core/errors/result.dart
//
// Result pattern — abstraksi untuk hasil operasi asynchronous.
// Sumber: PROJECT-SETUP.md §15, TECHNICAL-DESIGN.md §11.
//
// ATURAN:
// - Repository dan use case mengembalikan Result<T>, bukan melempar exception.
// - UI tidak bergantung pada exception mentah.
// - Gunakan pattern matching (when / map) untuk menangani kedua case.

import 'failures.dart';

/// Representasi hasil operasi yang dapat berhasil atau gagal.
///
/// Gunakan [Result.success] dan [Result.failure] sebagai factory.
///
/// Contoh penggunaan:
/// ```dart
/// final result = await authRepository.login(username, password);
/// switch (result) {
///   case Success(:final data):
///     // gunakan data
///   case Failure(:final failure):
///     // tampilkan failure.userMessage
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Buat result sukses dengan data.
  const factory Result.success(T data) = Success<T>;

  /// Buat result gagal dengan failure.
  const factory Result.failure(Failure failure) = AppFailure<T>;

  /// Kembalikan true jika sukses.
  bool get isSuccess => this is Success<T>;

  /// Kembalikan true jika gagal.
  bool get isFailure => this is AppFailure<T>;

  /// Ambil data jika sukses, null jika gagal.
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        AppFailure() => null,
      };

  /// Ambil failure jika gagal, null jika sukses.
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        AppFailure(:final failure) => failure,
      };

  /// Transformasi data jika sukses.
  ///
  /// Jika gagal, kembalikan failure yang sama.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success(:final data) => Result.success(transform(data)),
        AppFailure(:final failure) => Result.failure(failure),
      };

  /// Transformasi data asynchronous jika sukses.
  Future<Result<R>> mapAsync<R>(
    Future<Result<R>> Function(T data) transform,
  ) async =>
      switch (this) {
        Success(:final data) => transform(data),
        AppFailure(:final failure) => Result.failure(failure),
      };

  /// Eksekusi callback sesuai state.
  void when({
    required void Function(T data) onSuccess,
    required void Function(Failure failure) onFailure,
  }) {
    switch (this) {
      case Success(:final data):
        onSuccess(data);
      case AppFailure(:final failure):
        onFailure(failure);
    }
  }

  /// Ambil nilai dengan fallback jika gagal.
  T getOrElse(T defaultValue) => switch (this) {
        Success(:final data) => data,
        AppFailure() => defaultValue,
      };
}

/// Result sukses.
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

/// Result gagal.
///
/// Nama [AppFailure] dipilih untuk menghindari konflik dengan
/// kelas [Failure] dari failures.dart.
final class AppFailure<T> extends Result<T> {
  const AppFailure(this.failure);

  final Failure failure;
}
