/// An abstract class for a command.
///
/// A command is a task that can be executed and potentially undone.
abstract class Command {
  /// Executes the command.
  Future<void> execute();

  /// Undoes the command.
  ///
  /// This method should only be called after [execute] has been called.
  ///
  /// If a command cannot be undone, this method should throw an [UnsupportedError].
  Future<void> undo();
}
