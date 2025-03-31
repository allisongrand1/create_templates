sealed class FeatureEvents {
  static FeatureEvents feature() => FeatureEvent();
}

class FeatureEvent extends FeatureEvents {}

extension FeatureEventsExtension<T> on FeatureEvents {
  T map({
    required T Function(FeatureEvent) init,
  }) {
    return switch (this) {
      FeatureEvent event => init(event),
    };
  }
}
