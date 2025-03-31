import 'package:flutter_bloc/flutter_bloc.dart';

class FeatureBloc extends Bloc<FeatureEvents, FeatureStates> {
  FeatureBloc() : super(InitFeatureState()) {
    on<FeatureEvents>(
      (event, emit) => event.map(
        init: (event) => _init(event, emit),
      ),
    );
  }

  Future<void> _init(FeatureEvent event, Emitter<FeatureStates> emit) async {}
}
