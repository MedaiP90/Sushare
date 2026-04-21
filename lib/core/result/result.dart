sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final Object error;
}

extension ResultExtension<T> on Result<T> {
  bool get isOk => this is Ok<T>;
  T get value => (this as Ok<T>).value;
  Object get error => (this as Err<T>).error;

  R fold<R>({required R Function(T) onOk, required R Function(Object) onErr}) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };
}
