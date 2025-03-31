sealed class AuthEvents {
  static AuthEvents feature() => AuthEvent();
}

class AuthEvent extends AuthEvents {}

extension AuthEventsExtension<T> on AuthEvents {
  T map({
    required T Function(AuthEvent) init,
  }) {
    return switch (this) {
      AuthEvent event => init(event),
    };
  }
}
