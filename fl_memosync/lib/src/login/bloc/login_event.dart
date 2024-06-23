// ignore_for_file: public_member_api_docs
part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginChangeView extends LoginEvent {
  const LoginChangeView(this.view);

  final LoginViews view;

  @override
  List<Object> get props => [view];
}
