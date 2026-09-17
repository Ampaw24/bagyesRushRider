# Flutter UI/UX Simplification & Modernization Prompt

You are a **senior Flutter engineer and senior UI/UX designer** reviewing an existing Flutter application's UI.

Your task is to **audit and modernize the entire UI while simplifying the visual design**.

The goal is NOT to redesign the application unnecessarily.

The goal is to make the existing screens:

> **Simple, clean, modern, professional, consistent, functional, and visually calm.**

The application should look like a professionally designed modern mobile product — **not flashy, overly decorative, or AI-generated.**

---

## 1. FIRST — AUDIT THE EXISTING UI

Before making changes, inspect the existing Flutter project and identify:

* Screens/pages
* Reusable widgets
* Theme configuration
* Color definitions
* Typography
* Buttons
* Cards
* Bottom sheets
* Dialogs
* Input fields
* Navigation
* App bars
* Tabs
* Lists
* Empty states
* Loading states
* Error states
* Animations
* Gradients
* Shadows
* Decorative elements

Understand the existing design system before modifying it.

**Do not immediately rewrite everything.**

Determine which components can be improved through simplification and which should remain unchanged because they already follow good UI practices.

---

# 2. PRIMARY DESIGN OBJECTIVE

Remove unnecessary visual complexity.

The UI should prioritize:

1. Usability
2. Readability
3. Consistency
4. Accessibility
5. Visual hierarchy
6. Performance
7. Modern design

Avoid designing elements simply because they "look impressive."

Every visual element should have a functional purpose.

---

# 3. REMOVE GRADIENTS

Remove unnecessary gradients throughout the application.

This includes gradients on:

* Buttons
* Cards
* Backgrounds
* Headers
* App bars
* Bottom sheets
* Containers
* Promotional sections
* Floating elements
* Decorative UI

### Buttons

Buttons should generally use:

**One solid background color + readable text + subtle state feedback.**

Avoid:

```dart
LinearGradient(...)
RadialGradient(...)
SweepGradient(...)
```

unless a gradient is genuinely required by an existing brand asset or specific design requirement.

Do not replace gradients with another decorative effect.

Use solid colors from the application's existing design system.

---

# 4. SIMPLIFY BUTTONS

Buttons should look modern and straightforward.

Preferred characteristics:

* Solid background
* Clear text
* Appropriate font weight
* Moderate border radius
* Comfortable horizontal/vertical padding
* Clear disabled state
* Clear pressed state
* Clear loading state
* Consistent height
* Consistent typography

Avoid:

* Gradient buttons
* Excessive shadows
* Glowing effects
* Inner shadows
* 3D buttons
* Excessive borders
* Decorative icons unless useful
* Excessive rounded/pill shapes

Do not make every button completely circular or pill-shaped.

Use border radius consistently across the application.

---

# 5. REDUCE EXCESSIVE BORDER RADIUS

Review all rounded containers.

Avoid making every element excessively rounded.

Do not use extremely large values such as:

```dart
BorderRadius.circular(50)
BorderRadius.circular(100)
```

unless the element is intentionally a pill/chip control.

Use moderate corner radii appropriate to the component.

For example:

* Buttons: moderate radius
* Cards: moderate radius
* Input fields: moderate radius
* Dialogs: moderate radius
* Bottom sheets: appropriate top radius
* Chips: pill shape only when appropriate

The UI should feel refined rather than cartoon-like.

---

# 6. REMOVE UNNECESSARY SHADOWS

Audit all shadows.

Remove excessive:

* Box shadows
* Drop shadows
* Glow effects
* Heavy elevation
* Multiple layered shadows

Prefer subtle elevation only when it helps establish hierarchy.

Flat UI is acceptable when elevation does not provide meaningful information.

Do not add shadows simply to make components appear "premium."

---

# 7. SIMPLIFY CARDS

Review all cards.

Cards should only be used when they provide meaningful grouping or hierarchy.

Avoid:

**Card inside card inside card.**

Avoid:

* Excessive shadows
* Gradients
* Decorative borders
* Multiple visual effects
* Excessive padding
* Large empty spaces

Prefer:

* Clean background
* Simple border or subtle elevation
* Clear typography
* Good spacing
* Strong content hierarchy

If a card does not need to be a card, consider replacing it with a simple container or section.

---

# 8. SIMPLIFY BACKGROUNDS

Avoid complicated backgrounds.

Remove unnecessary:

* Gradients
* Decorative blobs
* Abstract shapes
* Glows
* Patterns
* Excessive illustrations
* Floating decorations

Prefer:

* Clean solid backgrounds
* Existing brand colors
* Neutral surfaces
* Clear contrast

The background should support the content, not compete with it.

---

# 9. TYPOGRAPHY

Use typography to create hierarchy rather than decorative effects.

Establish a consistent hierarchy for:

* Page titles
* Section titles
* Subtitles
* Body text
* Labels
* Captions
* Buttons
* Form fields
* Navigation

Avoid:

* Excessive font weights
* Too many font sizes
* Unnecessary uppercase text
* Decorative fonts
* Inconsistent typography

Use the existing application font/design system where appropriate.

Do not introduce a new font without a good reason.

---

# 10. COLOR SYSTEM

Do not introduce random colors.

Use the application's existing:

* Primary color
* Secondary color
* Background colors
* Surface colors
* Text colors
* Error color
* Success color
* Warning color
* Disabled colors

Create/use centralized theme values where possible.

Avoid:

* Random hex values scattered throughout the project
* Multiple shades of the same color without purpose
* Neon colors
* Excessively saturated backgrounds
* Unnecessary gradients

The color system should be intentional and consistent.

---

# 11. ICONS

Keep icons simple and consistent.

Avoid:

* Mixing multiple icon styles
* Oversized decorative icons
* Icons with unnecessary backgrounds
* Excessive icon containers
* Decorative icons that don't communicate meaning

Use icons primarily when they improve understanding or navigation.

---

# 12. ANIMATIONS

Do NOT remove all animations.

Instead, remove **unnecessary or distracting animations**.

Keep animations that improve:

* Navigation
* Feedback
* Loading
* State changes
* User understanding

Prefer subtle:

* Fade
* Scale
* Slide
* Page transitions

Avoid:

* Constant floating animations
* Excessive bouncing
* Glowing animations
* Continuous background motion
* Large parallax effects
* Animating every component

Animations should feel natural and fast.

Also respect:

```text
prefers-reduced-motion
```

where applicable.

---

# 13. SPACING

Improve spacing consistency.

Use a coherent spacing system instead of random values throughout the application.

Review:

* Screen padding
* Section spacing
* Card padding
* Button padding
* Input spacing
* List item spacing
* Text spacing

Avoid both:

**Crowded layouts**

and

**Excessively empty layouts.**

The goal is balanced visual rhythm.

---

# 14. RESPONSIVE UI

Ensure screens work properly across:

* Small phones
* Standard phones
* Large phones
* Tablets

Do not rely on hardcoded dimensions where they can cause layout problems.

Prefer:

* `MediaQuery`
* `LayoutBuilder`
* Flexible
* Expanded
* FractionallySizedBox
* Adaptive constraints
* Responsive spacing

Avoid unnecessary fixed widths/heights.

Do not break existing functionality while improving responsiveness.

---

# 15. COMPONENT CONSISTENCY

Create or improve reusable components where appropriate.

For example:

```text
AppButton
PrimaryButton
SecondaryButton
AppTextField
AppCard
SectionHeader
LoadingIndicator
EmptyState
ErrorState
AppDialog
```

Do not duplicate the same UI implementation across multiple screens.

If the application already has reusable components, improve and reuse them rather than creating duplicates.

---

# 16. STATES

Every important interactive component should have appropriate states.

Review:

### Buttons

* Default
* Pressed
* Disabled
* Loading

### Inputs

* Default
* Focused
* Error
* Disabled
* Filled

### Lists

* Loading
* Loaded
* Empty
* Error
* Refreshing

### Network-dependent screens

* Loading
* Success
* Error
* Retry

Keep these states visually simple.

---

# 17. SCREEN-BY-SCREEN REVIEW

Review every screen individually.

For each screen ask:

### Does this element have a purpose?

### Is the hierarchy clear?

### Is anything visually excessive?

### Can this component be simplified?

### Is the CTA obvious?

### Is the content easy to scan?

### Are the colors consistent?

### Are spacing and alignment consistent?

### Are there unnecessary gradients?

### Are there unnecessary shadows?

### Are there unnecessary animations?

### Are there unnecessary cards?

### Is the screen still modern after simplifying it?

---

# 18. DO NOT OVER-CORRECT

This is important.

Do NOT interpret "simple" as:

* Old-fashioned
* Plain
* Unstyled
* Boring
* Completely flat
* Removing all visual hierarchy
* Removing all brand identity

The target is:

**Minimal but polished.**

The application should still feel like a modern commercial product.

---

# 19. PRESERVE FUNCTIONALITY

This is primarily a UI/UX modernization task.

Do not unnecessarily change:

* API logic
* Business logic
* State management
* Navigation logic
* Authentication
* Payment functionality
* Database functionality
* Networking
* Existing feature behavior

Only modify non-UI code when necessary to support a UI improvement.

If a UI change requires touching existing logic, understand the existing implementation first.

---

# 20. CODE QUALITY

Follow Flutter best practices.

Ensure:

* Clean Dart code
* Reusable widgets
* Proper separation of concerns
* No unnecessary duplication
* No unnecessary rebuilds
* No hardcoded repeated styling
* Centralized theme values
* Meaningful widget names
* Maintainable architecture

Do not create massive widget trees when smaller reusable widgets would improve maintainability.

---

# 21. BEFORE/AFTER DESIGN RULE

For every major visual change, ask:

> "Does this change improve usability, hierarchy, readability, consistency, or brand clarity?"

If the answer is no, do not add it.

The design should become **simpler, not more elaborate**.

---

# 22. FINAL VISUAL STANDARD

The finished application should have the visual character of a modern production mobile application:

* Clean
* Minimal
* Professional
* Responsive
* Consistent
* Easy to understand
* Fast
* Accessible
* Brand-aware
* Modern without being trendy
* Visually calm

### Specifically avoid:

❌ Gradient buttons
❌ Gradient backgrounds
❌ Excessive shadows
❌ Glowing effects
❌ Excessive rounded corners
❌ Decorative blobs
❌ Excessive glassmorphism
❌ Excessive animations
❌ 3D effects
❌ Visually noisy layouts
❌ Random colors
❌ Random typography
❌ Unnecessary cards
❌ Over-designed UI

### Prefer:

✅ Solid colors
✅ Strong typography
✅ Consistent spacing
✅ Clear hierarchy
✅ Subtle elevation
✅ Simple borders
✅ Moderate corner radius
✅ Meaningful icons
✅ Subtle transitions
✅ Responsive layouts
✅ Consistent components
✅ Accessible interactions
✅ Existing brand identity

---

# 23. EXECUTION PROCESS

Follow this workflow:

### Phase 1 — Audit

Inspect the entire application UI and identify areas that violate the design principles above.

### Phase 2 — Design System

Review and consolidate:

* Colors
* Typography
* Buttons
* Inputs
* Cards
* Spacing
* Radius
* Shadows
* Icons

### Phase 3 — Component Improvements

Improve shared components first.

This ensures changes propagate consistently throughout the application.

### Phase 4 — Screen Improvements

Review screens individually and apply the simplified design system.

### Phase 5 — Responsive Review

Test layouts across different screen sizes.

### Phase 6 — Final UI Audit

Search the project for:

* `LinearGradient`
* `RadialGradient`
* Excessive `BoxShadow`
* Excessive `BorderRadius`
* Hardcoded colors
* Duplicate button styles
* Duplicate card styles
* Excessive animations
* Inconsistent padding/margins

Remove or refactor unnecessary implementations.

---

# 24. FINAL REQUIREMENT

Do not simply make the application "less fancy."

Make it **intentionally simple**.

The final result should communicate:

> **"This is a professionally designed modern application where the product and content are more important than visual effects."**

Do not add new visual effects to compensate for removing gradients or decorative elements.

**Simplify. Refine. Standardize. Modernize.**
