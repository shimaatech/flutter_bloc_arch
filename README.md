# flutter_bloc_arch

A library that helps structuring flutter apps using the BLoC library

## Getting Started

This library is built upon the flutter [bloc](https://pub.dev/packages/bloc) library.
It allows developers to structure their app into components, where each component has its own bloc.

## Library contents

### BaseBloc

The `BaseBloc` class is the class that each bloc should inherit from. It inherits from the `Bloc`
class of the `bloc` library.
The `BaseBloc` class adds additional functionality like initialization and error handling.

Example of `MovieItemBloc` that inherits from `BaseBloc`:
For the full example, please check the [example](https://github.com/shimaatech/flutter_bloc_arch/tree/master/example) in the library repository

```dart
// First we need to create the base bloc state which should extend from BlocState
class MovieItemState extends BlocState {}

// Then we create other states that are specific to this bloc
// The MovieItemStateFavoriteUpdated, is yielded when the movie is added or removed from the
// favorite list
class MovieItemStateFavoriteUpdated extends MovieItemState {
  final bool isFavorite;

  MovieItemStateFavoriteUpdated(this.isFavorite);

  @override
  List<Object> get props => [isFavorite];
}


// we need to define a base bloc event that inherits from BlocEvent
class MovieItemEvent extends BlocEvent {}

// Then we need to create events that are specific to this bloc.
// MovieItemEventToggleFavorite is used for adding/removing movie from the favorite list
class MovieItemEventToggleFavorite extends MovieItemEvent {}


// Here we define the bloc. It extends BaseBloc which receives MovieItemEvent and yields
// MovieItemState.
// This bloc is used for managing the state of a single movie item in the movies list
class MovieItemBloc extends BaseBloc<MovieItemEvent, MovieItemState> {
  final MoviesServices _moviesServices;
  final Movie movie;

  // This bloc depends on movies services and a specific movie
  MovieItemBloc(this._moviesServices, this.movie);

  // We need to override this eventToState() method in order to handle events and change the state
  // of the bloc
  @override
  Stream<MovieItemState> eventToState(MovieItemEvent event) async* {
    if (event is MovieItemEventToggleFavorite) {
      yield* _toggleFavorite();
    }
  }

  // We need to override the onInitialized() method in order to yield some state or add some
  // event upon bloc initialization
  @override
  Stream<MovieItemState> onInitialized() async* {
    yield* _notifyFavoriteUpdated();
  }

  // We need to override the initialize() method if there is a need to initialize anything when
  // the bloc is created
  @override
  Stream<StateInitializing> initialize() async* {
    // here we wait until the movies service is initialized
    await _moviesServices.initialized;
  }

  // This method handles the toggle favorite event. If the movie is in favorite list, then it is
  // removed, otherwise it's added to the favorite list
  Stream<MovieItemState> _toggleFavorite() async* {
    if (_moviesServices.isFavorite(movie)) {
      await _moviesServices.removeFavoriteMovie(movie);
    } else {
      await _moviesServices.addFavoriteMovie(movie);
    }
    // in the end we notify listeners by yielding the new state
    yield* _notifyFavoriteUpdated();
  }

  // a shortcut method for changing the state to MovieItemStateFavoriteUpdated in order to notify
  // listeners that the favorite state of the movie has changed
  Stream<MovieItemStateFavoriteUpdated> _notifyFavoriteUpdated() async* {
    yield MovieItemStateFavoriteUpdated(_moviesServices.isFavorite(movie));
  }


}
```



