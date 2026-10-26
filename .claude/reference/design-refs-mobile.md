# Design references for mobile screens (flutter profile)

The `ref:` of `## Look` for a Flutter screen comes from, in this order: the card (Figma, a capture), the repo's design system, this
list. The reference sets the level (quality, depth, motion, type), never the composition. Each URL below loads; one that stops
loading is declared in `rondas.md` and replaced by the next.

## Motion and components (Material 3)

- https://m3.material.io/styles/motion/overview · the principles of motion: what moves, why, and how long it takes.
- https://m3.material.io/styles/motion/easing-and-duration · the easing curves and the duration tokens; copy the values, not the feel.
- https://m3.material.io/components · every component with its states: the reference for a control that answers press, focus and disabled.
- https://m3.material.io/foundations/accessible-design/overview · touch targets, contrast and focus order on a phone.
- https://material-foundation.github.io/material-theme-builder/ · a full color scheme from one seed color: tonal roles to copy into `ThemeData`.

## Layout, type and motion (Apple)

- https://developer.apple.com/design/human-interface-guidelines/motion · purposeful motion, what to leave still, reduced motion.
- https://developer.apple.com/design/human-interface-guidelines/layout · safe areas, margins and adaptive layouts.
- https://developer.apple.com/design/human-interface-guidelines/typography · a type scale and dynamic type at several sizes.
- https://developer.apple.com/design/human-interface-guidelines/accessibility · the minimum bar for an iOS screen: labels, targets, contrast.
- https://developer.android.com/design/ui/mobile · the Android side of layout, navigation and adaptive screens.

## Flutter

- https://docs.flutter.dev/ui/animations · the animation families (implicit, explicit, hero, page) and when each fits.
- https://docs.flutter.dev/ui/animations/hero-animations · a shared element between two routes, with the code.
- https://docs.flutter.dev/ui/accessibility · semantics, contrast and text scaling in Flutter.

## Native apps in use

- https://mobbin.com · real screens and flows of shipped apps by pattern (onboarding, empty state, settings): look at the sequence of states.
- https://rive.app/community · interactive animations that react to input: look at how a state change is drawn, not at the asset.
