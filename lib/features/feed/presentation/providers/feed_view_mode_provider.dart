import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple boolean: false = List, true = Grid
final isGridModeProvider = StateProvider<bool>((ref) => false);
