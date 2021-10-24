part of 'theme_cubit.dart';

@immutable
class ThemeState extends Equatable {
  final Brightness brightness;

  ThemeState({
    required this.brightness,
  });

  // final CardTheme cardTheme = CardTheme(
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadii.gentlyRounded,
  //   ),
  // );

  final AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: Colors.grey[850],
    centerTitle: true,
    elevation: 0,
  );

  final InputDecorationTheme inputDecorationTheme = const InputDecorationTheme(
    border: OutlineInputBorder(),
    isDense: true,
  );

  bool get isDarkTheme => (brightness == Brightness.dark);

  ThemeData get themeData {
    return ThemeData(
      appBarTheme: appBarTheme,
      brightness: brightness,
      // cardTheme: cardTheme,
      inputDecorationTheme: inputDecorationTheme,
      toggleableActiveColor: Colors.lightBlueAccent,
    );
  }

  ThemeState copyWith({
    Brightness? brightness,
  }) {
    return ThemeState(
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  List<Object> get props => [brightness];
}
