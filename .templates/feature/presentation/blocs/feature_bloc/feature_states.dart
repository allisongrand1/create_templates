sealed class FeatureStates {
  static FeatureStates init() => InitFeatureState();
  static FeatureStates loading() => InitFeatureState();
  static FeatureStates loaded() => InitFeatureState();
  static FeatureStates error() => InitFeatureState();
}

class InitFeatureState extends FeatureStates {}

class LoadingFeatureState extends FeatureStates {}

class LoadedFeatureState extends FeatureStates {}

class ErrorFeatureState extends FeatureStates {}

extension FeatureStatesExtension<T> on FeatureStates {
  T map({
    required T Function() init,
    required T Function() loading,
    required T Function(LoadedFeatureState state) loaded,
    required T Function(ErrorFeatureState error) error,
  }) {
    return switch (this) {
      InitFeatureState _ => init(),
      LoadingFeatureState _ => loading(),
      LoadedFeatureState state => loaded(state),
      ErrorFeatureState state => error(state),
    };
  }
}
