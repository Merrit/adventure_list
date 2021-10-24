import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:meta/meta.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/domain.dart';
import '../../../infrastructure/auth/src/google_auth_repository.dart';
import '../../../infrastructure/todos/todo_repository.dart';

part 'home_state.dart';

/// Allow calling HomeCubit without `context` since it is single-instance.
late HomeCubit homeCubit;

class HomeCubit extends Cubit<HomeState> {
  final GoogleAuthRepository _googleAuthRepository;

  HomeCubit(this._googleAuthRepository)
      : super(
          const HomeState(
            activeList: null,
            authenticated: false,
            awaitingAuth: true,
            drawerIsVisible: true,
            loading: false,
            loadingTodoLists: false,
            todoLists: [],
          ),
        ) {
    homeCubit = this;
    init();
  }

  final _emptyTodoList = TodoList(
    id: '',
    name: '',
    source: TodoSource.local,
    todos: [],
  );

  Future<void> init() async {
    bool authenticated;
    if (_googleAuthRepository.isAuthenticated) {
      authenticated = true;
      _getTodos();
    } else {
      authenticated = false;
    }
    emit(state.copyWith(
      authenticated: authenticated,
      awaitingAuth: false,
    ));
  }

  Future<bool> signInGoogle() async {
    emit(state.copyWith(awaitingAuth: true));
    final successful = await _googleAuthRepository.signIn(
      callback: _googleAuthCallback,
    );
    emit(state.copyWith(
      awaitingAuth: false,
      authenticated: successful,
    ));
    if (successful) _getTodos();
    return successful;
  }

  Future<void> _getTodos() async {
    emit(state.copyWith(loadingTodoLists: true));
    final successful = await _getTodoRepository();
    if (successful) await getTodoLists();
    emit(state.copyWith(loadingTodoLists: false));
  }

  late auth.AuthClient client;
  late TodoRepository _todoRepository;

  Future<bool> _getTodoRepository() async {
    final repo = await TodoRepository.google(_googleAuthRepository);
    if (repo == null) {
      return false;
    } else {
      _todoRepository = repo;
      return true;
    }
  }

  Future<void> getTodoLists() async {
    List<TodoList> todoLists;
    try {
      todoLists = await _todoRepository.getTodoLists();
    } on Exception {
      // If we can't access the user's data we need to re-authenticate.
      logOut();
      return;
    }
    TodoList? activeList;
    if (state.activeList != null) {
      activeList = todoLists.singleWhereOrNull(
        (element) => element.id == state.activeList!.id,
      );
    }
    emit(state.copyWith(
      activeList: activeList,
      todoLists: todoLists,
    ));
  }

  /// Triggered when Google authentication is requested,
  /// the user will need to grant access in a new browser tab.
  Future<void> _googleAuthCallback(String url) async {
    emit(state.copyWith(awaitingAuth: true));
    await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';
  }

  Future<void> createList(String name) async {
    emit(state.copyWith(loading: true));
    final newList = await _todoRepository.createList(name);
    if (newList == null) return;
    state.todoLists.add(newList);
    emit(state.copyWith(
      activeList: newList,
      loading: false,
    ));
  }

  Future<void> deleteList(TodoList list) async {
    emit(state.copyWith(loading: true));
    final activeListDeleted = (state.activeList == list);
    await _todoRepository.deleteList(list);
    await getTodoLists();
    emit(state.copyWith(
      activeList: (activeListDeleted) ? _emptyTodoList : null,
      loading: false,
    ));
  }

  void loadList(TodoList list) {
    emit(state.copyWith(activeList: list));
  }

  Future<void> createTodo(String name) async {
    if (state.activeList == null) return;
    final rawTodo = Todo(
      iCalUID: '', // auto-populated by the server.
      id: '', // auto-populated by the server.
      isComplete: false,
      title: name,
    );
    final newTodo = await _todoRepository.createTodo(
      list: state.activeList!,
      todo: rawTodo,
    );
    state.activeList?.todos.add(newTodo);
    emit(state.copyWith());
  }

  Future<void> deleteTodo(Todo todo) async {
    await _todoRepository.deleteTodo(list: state.activeList!, todo: todo);
    getTodoLists();
  }

  Future<void> updateTodo(Todo todo) async {
    final updatedTodo = await _todoRepository.updateTodo(
      list: state.activeList!,
      todo: todo,
    );
    // TODO: Get index and re-insert at correct location.
    state.activeList?.todos.removeWhere(
      (element) => element.iCalUID == updatedTodo.iCalUID,
    );
    state.activeList?.todos.add(updatedTodo);
    emit(state.copyWith());
  }

  void toggleDrawer() {
    emit(state.copyWith(drawerIsVisible: !state.drawerIsVisible));
  }

  void logOut() {
    emit(
      state.copyWith(
        activeList: null,
        authenticated: false,
        todoLists: null,
      ),
    );
    _googleAuthRepository.logOut();
  }
}
