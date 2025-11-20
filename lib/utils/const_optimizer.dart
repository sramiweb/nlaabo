/// Utility for creating const-optimized widgets
/// Use these helpers to ensure const constructors are used where possible
library;

import 'package:flutter/material.dart';

class ConstOptimizer {
  /// Create const SizedBox with height
  static const SizedBox height(double value) => SizedBox(height: value);
  
  /// Create const SizedBox with width
  static const SizedBox width(double value) => SizedBox(width: value);
  
  /// Common spacing constants
  static const space4 = SizedBox(height: 4);
  static const space8 = SizedBox(height: 8);
  static const space12 = SizedBox(height: 12);
  static const space16 = SizedBox(height: 16);
  static const space24 = SizedBox(height: 24);
  static const space32 = SizedBox(height: 32);
  static const space48 = SizedBox(height: 48);
  
  static const spaceW4 = SizedBox(width: 4);
  static const spaceW8 = SizedBox(width: 8);
  static const spaceW12 = SizedBox(width: 12);
  static const spaceW16 = SizedBox(width: 16);
  static const spaceW24 = SizedBox(width: 24);
  
  /// Common dividers
  static const divider = Divider();
  static const verticalDivider = VerticalDivider();
  
  /// Empty containers
  static const empty = SizedBox.shrink();
}
