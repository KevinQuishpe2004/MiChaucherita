import 'package:flutter/material.dart';

/// Extensiones útiles para BuildContext
extension ContextExtension on BuildContext {
  /// Acceso rápido al tema
  ThemeData get theme => Theme.of(this);

  /// Acceso rápido al color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Acceso rápido al text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Acceso rápido al tamaño de pantalla
  Size get screenSize => MediaQuery.of(this).size;

  /// Ancho de pantalla
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Alto de pantalla
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Padding seguro (notch, etc)
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Verifica si es modo oscuro
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Muestra un SnackBar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Muestra un SnackBar de éxito
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Cierra el teclado
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

/// Extensiones para Widget
extension WidgetExtension on Widget {
  /// Aplica padding horizontal
  Widget paddingHorizontal(double value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: value),
      child: this,
    );
  }

  /// Aplica padding vertical
  Widget paddingVertical(double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: value),
      child: this,
    );
  }

  /// Aplica padding a todos los lados
  Widget paddingAll(double value) {
    return Padding(
      padding: EdgeInsets.all(value),
      child: this,
    );
  }

  /// Centra el widget
  Widget centered() {
    return Center(child: this);
  }

  /// Hace el widget expandible
  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }
}
