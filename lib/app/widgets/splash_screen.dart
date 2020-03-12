import 'package:flutter/material.dart';

import '../resources/theme.dart';

class SplashScreen extends StatelessWidget {
  final Color iconColor;
  final Gradient gradient;

  const SplashScreen({
    Key key,
    this.iconColor = Colors.white,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? context.brandTheme.splashScreenGradient,
      ),
      child: Center(
        child: Icon(
          context.brandTheme.logo,
          size: 64,
          color: iconColor,
        ),
      ),
    );
  }
}
