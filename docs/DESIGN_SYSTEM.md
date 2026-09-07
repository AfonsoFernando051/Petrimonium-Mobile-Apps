# Petrimonium mobile design system

## Purpose

Petrimonium should feel like one ecosystem without making its products look or
behave identically. The shared design system defines foundations and reusable
presentation primitives. Each app owns its visual emphasis, content hierarchy,
copy, navigation and product-specific components.

The implementation lives in `packages/petrimonium_ui`. This document describes
the rules for using and extending it; exported APIs in
`packages/petrimonium_ui/lib/petrimonium_ui.dart` describe the current surface.

## Product character

| Product | Experience | Current visual direction |
| --- | --- | --- |
| Academy | Guided learning and safe practice | Cosmic/dark foundation with cyan and violet accents |
| Wallet | Calm patrimony interpretation | Petrol/emerald accents; market loss is informative, not an alarm mechanic |
| Health | Clear, approachable cash-flow planning | Warm light surfaces and terracotta accents |

These differences are intentional. A shared package must not contain an
Academy/Wallet/Health switch or choose a product palette.

## Shared foundations

`petrimonium_ui` currently exports:

- `AppSpacing`, `AppRadii`, `AppMotion` and `AppTextStyles`;
- semantic `AppColorTokens` and `PetrimoniumBrandAccents`;
- `PetrimoniumTheme` and `ThemeController`;
- `GlassCard`/`CardSurface`, `GameButton`, `CustomTextField`;
- loading, empty and error states;
- logout confirmation, chart legend, tooltip summary and unavailable badge;
- a presentation-only fade route.

Academy and Wallet currently provide their own token values through
`lib/core/theme/app_palette.dart` and build `ThemeData` with
`PetrimoniumTheme`. Health currently owns `health_theme.dart` and does not yet
depend on `petrimonium_ui`; that is a current fact, not a recommendation to
force a migration.

## Composition and configuration

Shared UI receives variation rather than discovering the product:

```dart
SharedWidget(
  title: productCopy.title,
  illustration: productIllustration,
  optionalContent: productContent,
  onPrimaryAction: productAction,
)
```

Use these seams:

- colors from the active theme/token extensions;
- copy as parameters, never from an app string catalog imported by a package;
- assets as widgets, builders or references supplied by the app;
- behavior as callbacks or a narrow strategy;
- optional/reordered sections as child lists or builders.

Do not share screens through `AcademyPage extends BasePage`. A small stable
controller contract or adapter may use inheritance when it models behavior,
but screen inheritance is not the design-system architecture.

## Hierarchy and interaction

- One primary action should dominate a screen or card group.
- Use hierarchy before decoration: spacing, typography and grouping should do
  most of the work.
- Financial values must remain readable and auditable. Decorative effects
  cannot obscure the number, unit, period or simulation status.
- Academy simulations carry a persistent fictitious-data indicator.
- Wallet movement is presented calmly. Red is reserved for errors or semantics
  that truly require danger, not every negative market movement.
- Health must keep currency codes/meaning clear and must never imply conversion
  by changing presentation alone.
- Locked or unavailable content explains why and what the person can do next.
- Empty, loading and error states are designed states, not blank space.

## Pet and Mentor presentation

The Pet is a companion, not the primary content. Its presentation may use
Rive, Lottie, PNG or a future renderer; widgets must depend on a semantic state
or presenter, not on Rive as the domain interface.

Mentor messages should feel connected to the Pet and remain readable,
localizable and accessible. Keep dynamic text in Flutter rather than inside an
animation asset. Context/safety rules belong to the backend; mobile surfaces
show messages, loading/error states, actions and disclosures.

See [`PET_AND_MENTOR.md`](PET_AND_MENTOR.md) for the current component and
animation contracts.

## Accessibility

Every reusable component has a three-product blast radius. At minimum:

- preserve screen-reader names, roles and live-region behavior;
- provide at least 48 logical pixels for primary touch targets where practical;
- support text scaling without clipping primary copy or controls;
- do not communicate state by color alone;
- honor `MediaQuery.disableAnimations` and provide a stable reduced-motion
  result rather than freezing mid-transition;
- maintain contrast in every product palette, light and dark where supported;
- provide a textual equivalent for charts and non-text financial visuals.

## Motion

Motion should explain state, focus attention or strengthen a meaningful
learning/progression moment. It must not create urgency around investment
outcomes. Frequent interactions use short, restrained transitions; large
celebrations are reserved for genuine learning/progression milestones.

## Extending the design system

Before adding a shared primitive:

1. compare the need in all three apps;
2. verify that the shared part is structure/presentation, not product logic;
3. make copy, asset and behavior differences injectable;
4. test against a neutral palette and accessibility settings;
5. migrate consumers incrementally;
6. document any new token or stable interaction contract here.

If only one product should inherit a future fix, keep the component in that
app. Similar appearance is not sufficient evidence of shared ownership.
