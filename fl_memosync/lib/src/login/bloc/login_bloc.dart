// ignore_for_file: public_member_api_docs
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:memosync/src/services/logger.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<LoginChangeView>(_onLoginChangeView);
  }

  void _onLoginChangeView(
    LoginChangeView event,
    Emitter<LoginState> emit,
  ) {
    Logger.info('changeView event');
    emit(LoginState.changeView(state, event.view));
  }
}
