import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvents, AuthStates> {
  AuthBloc() : super(InitAuthState()) {
    on<AuthEvents>(
      (event, emit) => event.map(
        init: (event) => _init(event, emit),
      ),
    );
  }

  Future<void> _init(AuthEvent event, Emitter<AuthStates> emit) async {}
}
