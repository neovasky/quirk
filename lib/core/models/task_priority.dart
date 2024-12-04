import 'package:flutter/material.dart';

enum TaskPriority {
  high,
  medium,
  low;

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }
}