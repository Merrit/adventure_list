import 'package:equatable/equatable.dart';

class Todo extends Equatable {
  final String iCalUID;
  final String id;
  final bool isComplete;
  final String title;

  const Todo({
    required this.iCalUID,
    required this.id,
    required this.isComplete,
    required this.title,
  });

  @override
  List<Object> get props => [
        iCalUID,
        id,
        isComplete,
        title,
      ];

  Todo copyWith({
    String? iCalUID,
    String? id,
    bool? isComplete,
    String? title,
  }) {
    return Todo(
      iCalUID: iCalUID ?? this.iCalUID,
      id: id ?? this.id,
      isComplete: isComplete ?? this.isComplete,
      title: title ?? this.title,
    );
  }
}
