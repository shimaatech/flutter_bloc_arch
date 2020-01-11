# flutter_bloc_arch

A library that helps structuring flutter apps using the BLoC library

## Getting Started

This library is built upon the flutter [bloc](https://pub.dev/packages/bloc) library.
It allows developers to structure their app into components, where each component has its own bloc.

## Library contents

### `BaseBloc`

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


### `Component`
The `Component` class is a `StatelessWidget` that is attached to one `bloc`. The component just
describes how to create the `bloc` and how to create the `view` of this component.  
Another utility that is provided by the `Component` class, is the `stateListener` which allows
listening to state changes from the `bloc` that is attached to the `component`. The `stateListener`
is simply a `BlocListener` from the `BLoC` library.  


An Example of a `Component` that uses the `MovieItemBloc` from the example above:  
For the full example, please check the [example](https://github.com/shimaatech/flutter_bloc_arch/tree/master/example) in the library repository


```dart
/// A MovieItem component that is used for showing a single component.
/// The bloc that is used by this component is the MovieItemBloc
class MovieItem extends Component<MovieItemBloc> {
  final Movie movie;

  MovieItem(this.movie);

  @override
  MovieItemBloc createBloc(BuildContext context) {
    // in this method we create the MovieItemBloc
    return MovieItemBloc(MoviesServices.getInstance(), movie);
  }

  @override
  ComponentView<MovieItemBloc> createView(MovieItemBloc bloc) {
    // in this method we create the component view and pass it the created bloc
    return MovieItemView(bloc);
  }
  
  
  // override the stateListener method if you need to listen to states from the created bloc
  // (MovieItemBloc in our case).
  // Note that this is a listener and not a builder. It's useful for logging, navigation,
  // showing snack bars...
  @override
  void stateListener(BuildContext context, BlocState state) {
    if (state is StateError) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

}
```


### `ComponentView`

The `ComponentView` is used for building the view of the `component`. It has direct access to the
`bloc` created by the `component`, and it has some utilities for managing the state easily
using the `stateBuilder`  
You can also handle bloc initialization, and errors in the `ComponentView`. Check the [example](https://github.com/shimaatech/flutter_bloc_arch/tree/master/example) in the repository for more info

An Example of a `ComponentView` for the `MovieItem` component from the example above:  
For the full example, please check the [example](https://github.com/shimaatech/flutter_bloc_arch/tree/master/example) in the library repository

```dart
/// The view of the MovieItem component
class MovieItemView extends ComponentView<MovieItemBloc> {
  MovieItemView(MovieItemBloc bloc) : super(bloc);

  // This method builds the content of the component's view
  @override
  Widget buildView(BuildContext context) {
    final Movie movie = bloc.movie;
    return ListTile(
      leading: Image.network(movie.imageUrl),
      title: Text(movie.title),
      subtitle: Text(movie.year.toString()),
      trailing: _buildFavoriteIcon(),
    );
  }

  Widget _buildFavoriteIcon() {
    // The only state that is managed by the BlocItemBloc is the favorite state
    // Here we use a stateBuilder for rebuilding the favorite icon when the state is changed to
    // MovieIemStateFavoriteUpdated
    return stateBuilder<MovieItemStateFavoriteUpdated>(
        builder: (context, state) {
          return GestureDetector(
            child: Icon(state.isFavorite ? Icons.star : Icons.star_border),
            // When tapping the favorite icon, a MovieItemEventToggleFavorite event is dispatched
            onTap: () => bloc.event(MovieItemEventToggleFavorite()),
          );
        });
  }
}
```


The `ComponentView` class also allows to handle bloc initialization and errors.  
Here is an example for handling initialization and error while initializing the `MoviesView`

```dart
/// Creates the view for the MoviesComponent
class MoviesView extends ComponentView<MoviesBloc> {

  MoviesView(MoviesBloc bloc) : super(bloc);

  // override onInitializing() method in order to show something while the component's bloc is
  // being initialized
  @override
  Widget onInitializing(BuildContext context, StateInitializing loadingData) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Loading movies...'),
            LinearProgressIndicator(
              value: loadingData.progress,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget onInitializingError(BuildContext context, StateInitializationError error) {
    return Text("An error occurred while initializing movies: ${error.message}");
  }


  @override
  Widget buildView(BuildContext context) {
    ...
  }
}

```

### More on `stateBuilder`s