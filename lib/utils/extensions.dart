import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../db/database.dart';

extension CategoryX on PuzzleCategory {
  IconData get icon {
    switch (iconName) {
      case 'logic':
        return Icons.lightbulb;
      case 'memory':
        return Icons.memory;
      case 'science':
        return Icons.science;
      case 'text_fields':
        return Icons.text_fields;
      case 'calculate':
        return Icons.calculate;
      case 'pattern_sequence':
        return Icons.star;
      case 'visual':
        return Icons.wb_sunny;
      case 'visibility':
        return Icons.visibility;
      default:
        return Icons.extension;
    }
  }
}
