# Flutter UI Design Skill

## Context

Applies when the user prompts to "design", "create a screen", or "build UI".

## Aesthetic Constraints

- Grid & Spacing: Enforce strict 8dp grid scaling (8, 16, 24, 32) for padding and margins.
- Borders: Apply unified component corner radii (12px to 16px) for cards and modals.
- Color System: Use a seed-based ColorScheme. Apply one bold dominant color and sharp accent colors.
- Typography: Enforce clean text hierarchy (Display -> Headline -> Title -> Body) using TextThemes. Do not hardcode TextStyle sizes.
- Animations: Implement standard implicit transitions (AnimatedContainer, AnimatedOpacity) for state changes to achieve smooth 60/120 FPS rendering.