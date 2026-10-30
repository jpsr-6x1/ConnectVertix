import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectvertix/theme.dart';

void main() {
  test('tema escuro usa fundo preto', () {
    final theme = campusDarkTheme();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
  });
}
