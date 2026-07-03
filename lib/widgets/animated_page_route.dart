import 'package:flutter/material.dart';

/// A premium page route transition that combines a slide-up, fade-in,
/// and subtle scale effect for a smooth, polished screen entry.
class AnimatedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AnimatedPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Curved animation for a natural feel
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // 1. Slide up from 30% below
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.30),
              end: Offset.zero,
            ).animate(curved);

            // 2. Fade in
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curved);

            // 3. Scale from 85% to 100%
            final scaleAnimation = Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).animate(curved);

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}
