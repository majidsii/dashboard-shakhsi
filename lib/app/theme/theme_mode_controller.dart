import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardThemeModeProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.system,
);
