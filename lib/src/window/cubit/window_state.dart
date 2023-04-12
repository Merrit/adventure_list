part of 'window_cubit.dart';

@freezed
class WindowState with _$WindowState {
  const factory WindowState({
    /// Whether the window is pinned as a desktop widget or not.
    required bool pinned,
  }) = _WindowState;

  factory WindowState.initial() {
    return const WindowState(
      pinned: false,
    );
  }
}
