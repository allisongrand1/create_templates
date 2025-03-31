sealed class AuthStates {
  static AuthStates init() => InitAuthState();
  static AuthStates loading() => InitAuthState();
  static AuthStates loaded() => InitAuthState();
  static AuthStates error() => InitAuthState();
}

class InitAuthState extends AuthStates {}

class LoadingAuthState extends AuthStates {}

class LoadedAuthState extends AuthStates {}

class ErrorAuthState extends AuthStates {}

extension AuthStatesExtension<T> on AuthStates {
  T map({
    required T Function() init,
    required T Function() loading,
    required T Function(LoadedAuthState state) loaded,
    required T Function(ErrorAuthState error) error,
  }) {
    return switch (this) {
      InitAuthState _ => init(),
      LoadingAuthState _ => loading(),
      LoadedAuthState state => loaded(state),
      ErrorAuthState state => error(state),
    };
  }
}
