import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tg_home_provider.dart';
import '../theme/app_theme.dart';

/// Compact score + coins chips with a visible increase animation.
class BalanceBarChips extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const BalanceBarChips({
    super.key,
    this.padding = const EdgeInsets.only(right: 12),
  });

  @override
  Widget build(BuildContext context) {
    final tg = context.watch<TgHomeProvider>();
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedBalanceChip(
            icon: Icons.star_rounded,
            value: tg.totalScore,
            color: kAccentGold,
          ),
          const SizedBox(width: 6),
          _AnimatedBalanceChip(
            icon: Icons.monetization_on_rounded,
            value: tg.coins,
            color: const Color(0xFFFBBF24),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBalanceChip extends StatefulWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _AnimatedBalanceChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  State<_AnimatedBalanceChip> createState() => _AnimatedBalanceChipState();
}

class _AnimatedBalanceChipState extends State<_AnimatedBalanceChip>
    with TickerProviderStateMixin {
  late int _displayed;
  late int _from;
  int _delta = 0;

  late final AnimationController _countCtrl;
  late final AnimationController _popCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<double> _popScale;
  late final Animation<double> _popGlow;
  late final Animation<double> _floatY;
  late final Animation<double> _floatOpacity;
  late final Animation<double> _floatScale;

  final GlobalKey _chipKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _displayed = widget.value;
    _from = widget.value;

    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(_countCtrl.value);
        setState(() {
          _displayed = (_from + (_delta * t)).round();
        });
      });

    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.32), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.32, end: 0.90), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.10), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut));
    _popGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 75),
    ]).animate(_popCtrl);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _removeOverlay();
      });
    _floatY = Tween<double>(begin: 0, end: -28).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeOutCubic),
    );
    _floatOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 48),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_floatCtrl);
    _floatScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(_floatCtrl);
  }

  @override
  void didUpdateWidget(covariant _AnimatedBalanceChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;

    _from = _displayed;
    _delta = widget.value - _from;

    _countCtrl
      ..duration = Duration(
        milliseconds: (450 + (_delta.abs() * 10).clamp(0, 650)).toInt(),
      )
      ..forward(from: 0);

    _popCtrl.forward(from: 0);

    if (_delta > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showFloatOverlay();
      });
    } else {
      _removeOverlay();
    }
  }

  void _showFloatOverlay() {
    _removeOverlay();
    final box = _chipKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(context);
    if (box == null || overlay == null || !box.hasSize) return;

    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    final delta = _delta;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, _) {
            return Positioned(
              left: origin.dx,
              top: origin.dy + _floatY.value - 4,
              width: size.width,
              child: IgnorePointer(
                child: Material(
                  type: MaterialType.transparency,
                  child: Opacity(
                    opacity: _floatOpacity.value,
                    child: Transform.scale(
                      scale: _floatScale.value,
                      child: Text(
                        '+$delta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(color: Colors.black.withAlpha(160), blurRadius: 6),
                            Shadow(color: widget.color.withAlpha(160), blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(_overlayEntry!);
    _floatCtrl.forward(from: 0);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    _countCtrl.dispose();
    _popCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _popCtrl,
      builder: (context, _) {
        final increasing = _delta > 0;
        final glow = increasing ? _popGlow.value : 0.0;
        final scale = _popCtrl.isAnimating
            ? (increasing ? _popScale.value : (1.0 - 0.08 * _popGlow.value))
            : 1.0;

        return Transform.scale(
          key: _chipKey,
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color.lerp(
                widget.color.withAlpha(15),
                widget.color.withAlpha(70),
                glow,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.lerp(
                  widget.color.withAlpha(55),
                  widget.color,
                  glow,
                )!,
                width: 1 + glow * 1.2,
              ),
              boxShadow: glow > 0.04
                  ? [
                      BoxShadow(
                        color: widget.color.withAlpha((110 * glow).round()),
                        blurRadius: 14 * glow,
                        spreadRadius: 2 * glow,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.color, size: 14 + (2 * glow)),
                const SizedBox(width: 4),
                Text(
                  '$_displayed',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 12 + (2 * glow),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
