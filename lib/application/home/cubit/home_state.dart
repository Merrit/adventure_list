part of 'home_cubit.dart';

@immutable
class HomeState {
  final TodoList? activeList;
  final bool authenticated;
  final bool awaitingAuth;
  final bool loading;
  final bool loadingTodoLists;
  final bool drawerIsVisible;
  final List<TodoList> todoLists;

  const HomeState({
    required this.activeList,
    required this.authenticated,
    required this.awaitingAuth,
    required this.loading,
    required this.loadingTodoLists,
    required this.drawerIsVisible,
    required this.todoLists,
  });

  HomeState copyWith({
    TodoList? activeList,
    bool? authenticated,
    bool? awaitingAuth,
    bool? drawerIsVisible,
    bool? loading,
    bool? loadingTodoLists,
    List<TodoList>? todoLists,
  }) {
    TodoList? _newActiveList;
    if (activeList == null) {
      _newActiveList = this.activeList;
    } else if (activeList.id == '') {
      // Hack to re-null the active list when deleted.
      // This is needed to unpopulate the loaded list so that the
      // title, items, etc of a deleted list aren't still being displayed.
      _newActiveList = null;
    } else {
      _newActiveList = activeList;
    }
    return HomeState(
      activeList: _newActiveList,
      authenticated: authenticated ?? this.authenticated,
      awaitingAuth: awaitingAuth ?? this.awaitingAuth,
      drawerIsVisible: drawerIsVisible ?? this.drawerIsVisible,
      loading: loading ?? this.loading,
      loadingTodoLists: loadingTodoLists ?? this.loadingTodoLists,
      todoLists: todoLists ?? this.todoLists,
    );
  }
}
