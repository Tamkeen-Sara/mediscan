import 'package:flutter/material.dart';

/// Smooth page route with custom transition
class SmoothPageRoute<T> extends MaterialPageRoute<T> {
  SmoothPageRoute({
    required super.builder,
    required super.settings,
  });

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;
    final tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnim = animation.drive(tween);

    final fadeTween = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    final fadeAnim = animation.drive(fadeTween);

    return SlideTransition(
      position: offsetAnim,
      child: FadeTransition(opacity: fadeAnim, child: child),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);
}

/// Fade scale transition for dialogs
class FadeScaleTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const FadeScaleTransition({
    required this.animation,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
                scale: Tween(begin: 0.85, end: 1.0)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
      child: FadeTransition(
        opacity: Tween(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }
}

/// Slide up transition for bottom sheets
class SlideUpPageRoute<T> extends MaterialPageRoute<T> {
  SlideUpPageRoute({
    required super.builder,
    required super.settings,
  });

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;
    final tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnim = animation.drive(tween);

    return SlideTransition(position: offsetAnim, child: child);
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);
}

/// Staggered animation helper
class StaggeredAnimationBuilder extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Curve curve;
  final Duration duration;

  const StaggeredAnimationBuilder({
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 75),
    this.curve = Curves.easeOutCubic,
    this.duration = const Duration(milliseconds: 400),
    super.key,
  });

  @override
  State<StaggeredAnimationBuilder> createState() =>
      _StaggeredAnimationBuilderState();
}

class _StaggeredAnimationBuilderState extends State<StaggeredAnimationBuilder>
    with TickerProviderStateMixin {
  late List<AnimationController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      widget.children.length,
      (i) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    for (int i = 0; i < controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final ctrl in controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          AnimatedBuilder(
            animation: controllers[i],
            builder: (context, child) {
              final animation = Tween(begin: const Offset(0.0, 20.0), end: Offset.zero)
                  .animate(CurvedAnimation(
                    parent: controllers[i],
                    curve: widget.curve,
                  ));
              final fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: controllers[i],
                  curve: widget.curve,
                ),
              );

              return SlideTransition(
                position: animation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              );
            },
            child: widget.children[i],
          ),
      ],
    );
  }
}

/// Animated counter widget
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle style;

  const AnimatedCounter({
    required this.value,
    required this.style,
    super.key,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation =
        IntTween(begin: widget.value, end: widget.value).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = IntTween(begin: oldWidget.value, end: widget.value)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toString(),
          style: widget.style,
        );
      },
    );
  }
}
