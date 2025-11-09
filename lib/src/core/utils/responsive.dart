import 'package:flutter/material.dart';

enum DeviceSize { small, medium, large }

class Responsive {
  static DeviceSize deviceSize(BuildContext ctx) {
    final width = MediaQuery.of(ctx).size.width;
    if (width >= 1024) return DeviceSize.large;
    if (width >= 600) return DeviceSize.medium;
    return DeviceSize.small;
  }

  static bool isPhone(BuildContext ctx) => deviceSize(ctx) == DeviceSize.small;
  static bool isTablet(BuildContext ctx) => deviceSize(ctx) == DeviceSize.medium;
  static bool isLarge(BuildContext ctx) => deviceSize(ctx) == DeviceSize.large;
}
