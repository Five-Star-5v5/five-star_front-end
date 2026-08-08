import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Une étape du tuto guidé : on désigne un widget de l'écran via sa [key]
/// et on explique à quoi il sert.
class CoachMarkStep {
  /// Clé posée sur le widget à mettre en avant.
  final GlobalKey key;
  final String title;
  final String body;

  /// Marge entre le widget et le bord du trou découpé dans le voile.
  final double padding;

  /// Rayon des coins du trou.
  final double radius;

  const CoachMarkStep({
    required this.key,
    required this.title,
    required this.body,
    this.padding = 8,
    this.radius = 14,
  });
}

/// Vrai tant qu'un tuto est affiché. L'overlay se pose sur le Navigator
/// racine : deux tutos simultanés s'empileraient, le voile de l'un assombrissant
/// la bulle de l'autre. Un seul à la fois, quelle qu'en soit la source.
bool _coachMarksVisible = false;

/// Affiche un tuto guidé par-dessus l'écran courant.
///
/// Le futur se complète quand l'utilisateur a terminé ou passé le tuto.
/// Les étapes dont la cible n'est pas rendue à l'écran sont ignorées.
/// L'appel est ignoré si un tuto est déjà à l'écran.
Future<void> showCoachMarks(
  BuildContext context,
  List<CoachMarkStep> steps,
) async {
  if (steps.isEmpty || _coachMarksVisible) return;
  _coachMarksVisible = true;

  final overlay = Overlay.of(context);
  final completer = Completer<void>();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CoachMarkView(
      steps: steps,
      onDone: () {
        entry.remove();
        _coachMarksVisible = false;
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );

  overlay.insert(entry);
  return completer.future;
}

// ── Vue ─────────────────────────────────────────────────────────────────────

class _CoachMarkView extends StatefulWidget {
  const _CoachMarkView({required this.steps, required this.onDone});

  final List<CoachMarkStep> steps;
  final VoidCallback onDone;

  @override
  State<_CoachMarkView> createState() => _CoachMarkViewState();
}

class _CoachMarkViewState extends State<_CoachMarkView> {
  int _index = 0;

  /// Rect de la cible courante, recalculé après chaque défilement.
  Rect? _target;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(0));
  }

  /// Amène la cible à l'écran puis mémorise sa position.
  Future<void> _goTo(int i) async {
    // On saute les étapes dont la cible n'existe pas (widget non construit).
    while (i < widget.steps.length &&
        widget.steps[i].key.currentContext == null) {
      i++;
    }
    if (i >= widget.steps.length) {
      widget.onDone();
      return;
    }

    final ctx = widget.steps[i].key.currentContext!;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.35,
    );
    if (!mounted) return;

    // Laisse le layout se stabiliser avant de mesurer.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() {
      _index = i;
      _target = _rectOf(widget.steps[i]);
    });
  }

  Rect? _rectOf(CoachMarkStep step) {
    final ctx = step.key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return (origin & box.size).inflate(step.padding);
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onDone();
    } else {
      _goTo(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final step = widget.steps[_index];
    final target = _target;
    final isLast = _index == widget.steps.length - 1;

    // La bulle se place sous la cible si elle est dans la moitié haute,
    // au-dessus sinon — pour ne jamais recouvrir ce qu'on explique.
    // Sans cible mesurée, on la centre verticalement.
    double? bubbleTop;
    double? bubbleBottom;
    if (target == null) {
      bubbleTop = size.height * 0.4;
    } else if (target.center.dy < size.height / 2) {
      bubbleTop = target.bottom + 16;
    } else {
      bubbleBottom = size.height - target.top + 16;
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Stack(
          children: [
            // Voile percé. Tant que la cible n'est pas mesurée (première
            // frame), on peint le voile plein : TweenAnimationBuilder exige
            // un `end` non-null, et il n'y a de toute façon rien à animer.
            Positioned.fill(
              child: target == null
                  ? CustomPaint(
                      painter: _ScrimPainter(hole: null, radius: step.radius),
                    )
                  : TweenAnimationBuilder<Rect?>(
                      // `begin` est écrasé par le framework avec la valeur
                      // courante : c'est ce qui fait glisser le trou d'une
                      // cible à l'autre.
                      tween: RectTween(end: target),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      builder: (_, animated, _) => CustomPaint(
                        painter: _ScrimPainter(
                          hole: animated,
                          radius: step.radius,
                        ),
                      ),
                    ),
            ),
            // Bulle explicative
            Positioned(
              left: 16,
              right: 16,
              top: bubbleTop,
              bottom: bubbleBottom,
              child: _Bubble(
                step: step,
                index: _index,
                total: widget.steps.length,
                isLast: isLast,
                onNext: _next,
                onSkip: widget.onDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voile ───────────────────────────────────────────────────────────────────

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.hole, required this.radius});

  final Rect? hole;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.78);
    final full = Path()..addRect(Offset.zero & size);

    if (hole == null) {
      canvas.drawPath(full, scrim);
      return;
    }

    final rrect = RRect.fromRectAndRadius(hole!, Radius.circular(radius));
    final punched = Path.combine(
      PathOperation.difference,
      full,
      Path()..addRRect(rrect),
    );
    canvas.drawPath(punched, scrim);

    // Halo amber autour de la zone mise en avant
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.amber
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.amber,
    );
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter old) =>
      old.hole != hole || old.radius != radius;
}

// ── Bulle ───────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final CoachMarkStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A2C37), Color(0xFF16181E)],
              stops: [0.0, 0.8],
            ),
            border: Border.all(color: AppColors.border2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.amber, AppColors.amberD],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.title,
                      style: AppTypography.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1}/$total',
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.body,
                style: AppTypography.body(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.muted2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onSkip,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'Passer',
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.amberSoft, AppColors.amberD],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x47FF7F2A),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        isLast ? 'TERMINER' : 'SUIVANT',
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.06 * 10,
                          color: AppColors.night,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
