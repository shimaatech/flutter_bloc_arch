import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';

import 'app/app.dart';

void main() {
  BlocSupervisor.delegate = SimpleBlocDelegate();
  runApp(MoviesApp());
}

class SimpleBlocDelegate extends BlocDelegate {
  @override
  void onEvent(Bloc bloc, Object event) {
    super.onEvent(bloc, event);
    print('$bloc: $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('$bloc: $transition');
  }

  @override
  void onError(Bloc bloc, Object error, StackTrace stacktrace) {
    super.onError(bloc, error, stacktrace);
    print('$bloc: $error');
  }
}
