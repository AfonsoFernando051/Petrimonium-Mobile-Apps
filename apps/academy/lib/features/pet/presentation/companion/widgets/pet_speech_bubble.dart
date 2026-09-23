import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:petrimonium_academy/features/pet/presentation/companion/pet_companion_controller.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// Shows companion speech in the root overlay so it paints after the AppBar.
/// The measured avatar position and available viewport keep speech near the pet,
/// clear of the toolbar and navigation, even during scrolling or text scaling.
///
/// Painting in the root overlay also puts the bubble above any route pushed
/// on top of the host screen, where it has nothing to point at and covers
/// content — it once sat over a lesson's question stem. So it follows its
/// host route's `secondaryAnimation` and stays hidden while something else
/// is covering that route.
class PetSpeechBubbleOverlay extends StatefulWidget {
  const PetSpeechBubbleOverlay({
    super.key,
    required this.controller,
    this.anchor,
    this.onActionSelected,
    this.isMessageShownInline = false,
  });

  final PetCompanionController controller;

  /// Where the Pet actually renders on this screen. See
  /// [PetSpeechBubbleAnchor]'s doc comment.
  final PetSpeechBubbleAnchor? anchor;

  /// Invoked with the tapped action's destination context when the message
  /// has one — the host screen owns navigation (tab switches, pushes), this
  /// widget only reports the intent.
  final ValueChanged<PetMessageAction>? onActionSelected;

  /// Set by a host that already prints the companion's message in its own
  /// layout (Home does, inside `HomeCompanionCard`). The bubble then stays
  /// out of the way instead of repeating the same sentence on top of the
  /// card below it.
  final bool isMessageShownInline;

  @override
  State<PetSpeechBubbleOverlay> createState() => _PetSpeechBubbleOverlayState();
}

class _PetSpeechBubbleOverlayState extends State<PetSpeechBubbleOverlay> {
  OverlayEntry? _entry;

  /// The route this overlay was mounted from. Its `secondaryAnimation` runs
  /// 0 -> 1 as another route covers it, which is exactly when the bubble
  /// must get out of the way.
  ModalRoute<dynamic>? _hostRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hostRoute = ModalRoute.of(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final entry = OverlayEntry(builder: _buildOverlayContent);
      _entry = entry;
      Overlay.of(context).insert(entry);
    });
  }

  @override
  void didUpdateWidget(covariant PetSpeechBubbleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The bubble's own content listens to `controller` directly, so only
    // prop changes the OverlayEntry's builder closure wouldn't otherwise
    // pick up on its own (e.g. `anchor` swapping when the host switches
    // tabs) need an explicit rebuild request.
    if (oldWidget.controller != widget.controller ||
        oldWidget.anchor != widget.anchor ||
        oldWidget.isMessageShownInline != widget.isMessageShownInline ||
        oldWidget.onActionSelected != widget.onActionSelected) {
      // `OverlayEntry.markNeedsBuild` calls `setState` on the overlay's own
      // element — calling it synchronously here would happen *during* this
      // widget's own ancestor's build phase (that's what triggered
      // `didUpdateWidget`), which throws. Deferring to the next frame is
      // safe and invisible to the user (well under a frame's delay).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _entry?.markNeedsBuild();
      });
    }
  }

  Widget _buildOverlayContent(BuildContext context) {
    if (widget.isMessageShownInline) return const SizedBox.shrink();
    // This entry is rebuilt by the route transition's own animation, so it
    // can tick after the controller's owner has gone (a language switch
    // rebuilds the app from the root while this screen stays pushed).
    // Subscribing to a disposed ChangeNotifier throws.
    if (!mounted || widget.controller.isDisposed) return const SizedBox.shrink();
    final hostRoute = _hostRoute;
    if (hostRoute == null) return _buildBubble(context);
    return AnimatedBuilder(
      animation: hostRoute.secondaryAnimation ?? kAlwaysDismissedAnimation,
      builder: (context, _) {
        final covered = (hostRoute.secondaryAnimation?.value ?? 0) > 0 || !hostRoute.isCurrent;
        return covered ? const SizedBox.shrink() : _buildBubble(context);
      },
    );
  }

  Widget _buildBubble(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    // A transparent `Material` ancestor: this content is inserted into the
    // app's root `Overlay` (see class doc), which sits outside any
    // screen's own `Scaffold`/`Material` — without this, `PetComicSpeechBubble`'s
    // CTA `InkWell` has nothing to paint its ink response onto.
    return Material(
      type: MaterialType.transparency,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final message = widget.controller.currentMessage;
          return AnimatedSwitcher(
            duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.9,
                  end: 1.0,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
                child: child,
              ),
            ),
            child: message == null
                ? const SizedBox.shrink(key: ValueKey('empty'))
                : _AnchoredBubble(
                    key: ValueKey(message.id),
                    message: message,
                    controller: widget.controller,
                    anchor: widget.anchor,
                    onActionSelected: widget.onActionSelected,
                  ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _AnchoredBubble extends StatelessWidget {
  const _AnchoredBubble({
    super.key,
    required this.message,
    required this.controller,
    required this.anchor,
    required this.onActionSelected,
  });

  final PetMessage message;
  final PetCompanionController controller;
  final PetSpeechBubbleAnchor? anchor;
  final ValueChanged<PetMessageAction>? onActionSelected;

  Widget _bubble(PetBubbleTailPosition tail, double maxWidth) => PetComicSpeechBubble(
    message: message,
    translate: Translator.translate,
    dismissTooltip: Translator.translate(AppStrings.companionDismissTooltip),
    tailPosition: tail,
    maxWidth: maxWidth,
    onDismiss: controller.dismiss,
    onAction: () {
      if (message.action != null) {
        controller.dismiss();
        onActionSelected?.call(message.action!);
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final resolvedAnchor = anchor;
    if (resolvedAnchor == null) {
      return Align(alignment: Alignment.topCenter, child: _bubble(PetBubbleTailPosition.bottomLeft, 360));
    }

    final scrollPosition = resolvedAnchor.boxKey.currentContext == null
        ? null
        : Scrollable.maybeOf(resolvedAnchor.boxKey.currentContext!)?.position;
    if (scrollPosition != null) {
      return ListenableBuilder(
        listenable: scrollPosition,
        builder: (context, _) => _positionedBubble(context, resolvedAnchor),
      );
    }
    return _positionedBubble(context, resolvedAnchor);
  }

  Widget _positionedBubble(BuildContext context, PetSpeechBubbleAnchor anchor) {
    final box = anchor.boxKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    final viewport = Rect.fromLTRB(
      16,
      media.padding.top + kToolbarHeight + 8,
      media.size.width - 16,
      media.size.height - media.padding.bottom - 80,
    );
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.overlaps(Offset.zero & media.size)) return const SizedBox.shrink();
    final below = rect.top - viewport.top < viewport.bottom - rect.bottom;
    final fraction = rect.center.dx / media.size.width;
    final tail = fraction < .4
        ? (below ? PetBubbleTailPosition.topLeft : PetBubbleTailPosition.bottomLeft)
        : fraction > .6
        ? (below ? PetBubbleTailPosition.topRight : PetBubbleTailPosition.bottomRight)
        : (below ? PetBubbleTailPosition.topCenter : PetBubbleTailPosition.bottomCenter);
    return CustomSingleChildLayout(
      delegate: _BubbleViewportLayout(anchor: rect, viewport: viewport, below: below),
      child: SingleChildScrollView(child: _bubble(tail, viewport.width.clamp(0, 320))),
    );
  }
}

/// Uses the bubble's actual laid-out size, including translated text and text
/// scaling, so a long message cannot extend above the window or over the toolbar.
class _BubbleViewportLayout extends SingleChildLayoutDelegate {
  const _BubbleViewportLayout({required this.anchor, required this.viewport, required this.below});

  final Rect anchor;
  final Rect viewport;
  final bool below;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: viewport.width.clamp(0, 320), maxHeight: viewport.height.clamp(0, double.infinity));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (anchor.center.dx - childSize.width / 2).clamp(viewport.left, viewport.right - childSize.width);
    final desiredY = below ? anchor.bottom + 10 : anchor.top - childSize.height - 10;
    final y = desiredY.clamp(viewport.top, viewport.bottom - childSize.height);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_BubbleViewportLayout oldDelegate) =>
      anchor != oldDelegate.anchor || viewport != oldDelegate.viewport || below != oldDelegate.below;
}
