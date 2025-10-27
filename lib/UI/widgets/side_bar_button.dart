import 'package:flutter/material.dart';
import 'dart:ui';

class SideBarButton extends StatelessWidget {
  final String buttonText;
  final Function() onTap;
  final double height;
  final double largeFontSize;
  final bool isLeft;

  const SideBarButton({
    super.key,
    required this.buttonText,
    required this.onTap,
    required this.height,
    required this.largeFontSize,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final sidebarBorderRadius = deviceWidth * 0.07;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: isLeft
            ? Radius.circular(sidebarBorderRadius)
            : Radius.circular(0),
        bottomRight: isLeft
            ? Radius.circular(sidebarBorderRadius)
            : Radius.circular(0),
        topLeft: isLeft
            ? Radius.circular(0)
            : Radius.circular(sidebarBorderRadius),
        bottomLeft: isLeft
            ? Radius.circular(0)
            : Radius.circular(sidebarBorderRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.only(right: deviceWidth * 0.02),
            width: deviceWidth * 0.15,
            height: height,
            decoration: BoxDecoration(
              // Increased opacity for better visibility
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.only(
                topRight: isLeft
                    ? Radius.circular(sidebarBorderRadius)
                    : Radius.circular(0),
                bottomRight: isLeft
                    ? Radius.circular(sidebarBorderRadius)
                    : Radius.circular(0),
                topLeft: isLeft
                    ? Radius.circular(0)
                    : Radius.circular(sidebarBorderRadius),
                bottomLeft: isLeft
                    ? Radius.circular(0)
                    : Radius.circular(sidebarBorderRadius),
              ),
              border: Border.all(
                // More prominent border for better visibility
                color: Colors.white.withValues(alpha: 0.6),
                width: 2.0,
              ),
              // Add subtle gradient for depth and visibility
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: RotatedBox(
              quarterTurns: 1,
              child: Text(
                buttonText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: largeFontSize,
                  color: Colors.white,
                  // Bolder weight for better visibility
                  fontWeight: FontWeight.w700,
                  // Enhanced text shadows with multiple layers for better contrast
                  shadows: [
                    Shadow(
                      offset: Offset(0, 0),
                      blurRadius: 10.0,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 6.0,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 4.0,
                      color: Colors.black.withValues(alpha: 0.9),
                    ),
                  ],
                  // Add letter spacing for better readability
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
