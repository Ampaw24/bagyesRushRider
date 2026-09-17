

# Flutter UI/UX & Engineering Rules

These rules are **mandatory** whenever designing, modifying, refactoring, reviewing, or implementing UI in this Flutter project.

The objective is to maintain a:

> **Clean, modern, minimal, professional, responsive, maintainable, and highly usable Flutter application.**

The UI must prioritize:

1. Usability
2. Clarity
3. Consistency
4. Responsiveness
5. Accessibility
6. Maintainability
7. Performance
8. Product functionality

over unnecessary visual decoration.

---

# 1. CORE DESIGN PHILOSOPHY

Follow this principle:

> **Simple, modern, polished, functional — never flashy or unnecessarily decorative.**

The application should look like a professionally designed production mobile application.

Do not add visual effects simply because they make a screen look more impressive.

Every visual element must have a clear purpose.

Prefer:

* Clean layouts
* Strong visual hierarchy
* Consistent spacing
* Clear typography
* Solid colors
* Subtle elevation
* Moderate corner radius
* Simple icons
* Meaningful animations
* Reusable components
* Responsive layouts
* Clear states
* Maintainable code

Avoid:

* Over-designed interfaces
* Excessive decoration
* Visual noise
* Generic AI-generated UI patterns
* Trend-driven effects that do not improve usability
* Unnecessary abstractions
* Giant widgets/classes
* Duplicated UI implementations

---

# 2. NO GRADIENT UI

Gradients should NOT be used for normal UI components.

Avoid gradients on:

* Buttons
* Cards
* Backgrounds
* App bars
* Containers
* Bottom sheets
* Headers
* Navigation elements
* Input fields
* Floating elements

Avoid:

```dart
LinearGradient(...)
RadialGradient(...)
SweepGradient(...)
```

unless there is a specific existing brand or asset requirement that justifies the use.

### Buttons must use solid colors.

Prefer:

```dart
color: theme.colorScheme.primary
```

instead of gradient backgrounds.

Do not replace gradients with another decorative effect.

---

# 3. NO GLOW / NEON / 3D EFFECTS

Do not introduce:

* Glow effects
* Neon effects
* 3D buttons
* Inner shadows
* Strong drop shadows
* Fake depth effects
* Light flares
* Decorative blur
* Excessive glassmorphism

The UI should remain visually calm and professional.

---

# 4. BUTTON RULES

Buttons must be:

* Simple
* Clear
* Consistent
* Accessible
* Easy to tap

Preferred characteristics:

* Solid background color
* Clear typography
* Moderate corner radius
* Responsive sizing
* Appropriate internal spacing
* Clear pressed state
* Clear disabled state
* Clear loading state

Avoid:

* Gradient buttons
* Excessive shadows
* Glowing buttons
* 3D buttons
* Excessively rounded buttons
* Decorative effects

Do not make every button a pill.

Use pill-shaped buttons only when the component's purpose justifies it.

---

# 5. BORDER RADIUS

Use moderate and consistent corner radii.

Do not excessively round every component.

Avoid arbitrary values such as:

```dart
BorderRadius.circular(50)
BorderRadius.circular(100)
```

unless the component is intentionally a pill/chip.

Use a consistent radius system across:

* Buttons
* Cards
* Inputs
* Dialogs
* Bottom sheets
* Containers

The interface should feel refined rather than cartoon-like.

---

# 6. SHADOWS & ELEVATION

Use shadows sparingly.

Prefer subtle elevation only when it improves hierarchy.

Avoid:

* Heavy shadows
* Multiple layered shadows
* Large blur radius
* Dark floating shadows
* Decorative shadows

Flat surfaces are acceptable when elevation does not add meaningful hierarchy.

Do not add a shadow simply to make something look "premium."

---

# 7. CARDS

Do not turn every section into a card.

Use cards only when they provide meaningful grouping or separation.

Avoid:

> Card → Card → Card → Card

inside the same screen.

Prefer simple sections and containers where appropriate.

Cards should generally have:

* Clean surface
* Moderate radius
* Minimal border/elevation
* Clear hierarchy
* Appropriate responsive spacing

Avoid:

* Gradient cards
* Excessive shadows
* Decorative borders
* Excessive internal padding
* Multiple nested cards

---

# 8. BACKGROUNDS

Prefer clean backgrounds.

Use:

* Brand background colors
* Neutral surfaces
* Solid colors
* Clear contrast

Avoid:

* Decorative blobs
* Abstract shapes
* Gradient backgrounds
* Glowing backgrounds
* Unnecessary patterns
* Excessive illustrations

Backgrounds must support content rather than compete with it.

---

# 9. COLOR RULES

Use the project's established theme and brand colors.

Do NOT introduce random colors.

Avoid scattering raw colors throughout the code:

```dart
Color(0xFF...)
```

Prefer centralized theme/design-system values.

Colors should be intentionally assigned to:

* Primary
* Secondary
* Background
* Surface
* Text
* Border
* Success
* Warning
* Error
* Disabled states

Do not create unnecessary shades of the same color.

---

# 10. TYPOGRAPHY

Typography should create hierarchy.

Maintain consistent styles for:

* Page titles
* Section headings
* Body text
* Labels
* Captions
* Buttons
* Navigation
* Form fields

Avoid:

* Too many font sizes
* Excessive font weights
* Decorative fonts
* Random text styles
* Unnecessary uppercase text

Use the existing project font/design system.

Do not introduce another font without a strong reason.

---

# 11. RESPONSIVE SPACING & LAYOUT — STRICT RULE

## DO NOT USE FIXED LAYOUT DIMENSIONS AS THE DEFAULT

The application must be designed to work across different device sizes.

Do NOT use arbitrary constant values for:

* Screen padding
* Horizontal padding
* Vertical padding
* Margins
* Gaps
* Widths
* Heights
* Section spacing
* Card spacing
* Button dimensions
* Bottom-sheet dimensions
* Dialog dimensions
* Image dimensions
* Positioning

Avoid layouts such as:

```dart
padding: const EdgeInsets.all(24),
margin: const EdgeInsets.only(top: 30),
SizedBox(height: 40),
SizedBox(width: 250),
Container(
  width: 350,
  height: 200,
)
```

when those values are being used as rigid layout assumptions.

### IMPORTANT

This does NOT mean that Flutter constants such as `const` are forbidden.

`const` is encouraged for performance when appropriate.

The rule is:

> **Do not use rigid, device-independent layout measurements as the primary mechanism for positioning and sizing responsive UI.**

---

# 12. RESPONSIVE LAYOUT PRINCIPLES

Use the available screen space intelligently.

Prefer:

* `MediaQuery`
* `LayoutBuilder`
* `Flexible`
* `Expanded`
* `FractionallySizedBox`
* `ConstrainedBox`
* `AspectRatio`
* `Wrap`
* `Spacer`
* `SafeArea`
* Theme-based spacing
* Adaptive constraints
* Content-driven sizing

Use percentages, constraints, available dimensions, and intrinsic content sizing where appropriate.

For example, instead of:

```dart
Container(
  width: 350,
)
```

prefer a responsive constraint such as:

```dart
ConstrainedBox(
  constraints: BoxConstraints(
    maxWidth: ...,
  ),
)
```

or use the available parent constraints.

---

# 13. NO MAGIC NUMBERS

Do not scatter unexplained numeric values throughout UI code.

Examples of values requiring review:

```dart
SizedBox(height: 17)
SizedBox(width: 13)
Padding(
  padding: EdgeInsets.only(left: 27),
)
Container(
  height: 187,
)
```

Every fixed value must have a clear reason.

If a value represents a genuine design token, it should be centralized.

If a value is simply being used to force a layout into position, refactor the layout instead.

### Avoid "magic-number UI engineering."

Do not solve alignment problems by repeatedly changing numbers.

Fix the underlying layout structure.

---

# 14. RESPONSIVE SPACING SYSTEM

Spacing must be consistent while remaining responsive.

Do not randomly choose:

```text
8
11
13
17
21
27
31
43
```

for different parts of the interface.

Use a deliberate spacing system and allow spacing to adapt to available screen size where required.

Where the project has a design system, use its spacing tokens.

Where adaptive spacing is required, derive it from layout constraints rather than blindly hardcoding dimensions.

---

# 15. RESPONSIVE TYPOGRAPHY

Do not assume one font size works perfectly on every device.

Typography should respond appropriately to available space.

Avoid text overflow caused by rigid sizing.

Use:

* Appropriate text scaling
* Flexible layouts
* `maxLines`
* `TextOverflow`
* Responsive constraints
* Proper hierarchy

Do not arbitrarily reduce font sizes simply to make a layout fit.

Fix the layout first.

---

# 16. RESPONSIVE IMAGES

Images must adapt to their available space.

Avoid arbitrary fixed image dimensions where possible.

Prefer:

* `AspectRatio`
* `BoxFit`
* Parent constraints
* Responsive width
* Intrinsic sizing

Do not distort images to force them into a fixed container.

---

# 17. RESPONSIVE BOTTOM SHEETS & DIALOGS

Bottom sheets and dialogs must work across different screen sizes.

Do not assume:

```dart
height: 500
```

or similar fixed dimensions will work everywhere.

Prefer:

* Content-driven sizing
* `FractionallySizedBox`
* `DraggableScrollableSheet`
* Constraints
* Safe areas
* Available screen dimensions

Do not allow content to become clipped or inaccessible.

---

# 18. RESPONSIVE DESIGN TEST

Every screen must be considered for:

* Small phones
* Standard phones
* Large phones
* Tablets
* Different aspect ratios
* Different text lengths
* Accessibility text scaling

Before considering UI work complete, verify:

* No overflow
* No clipping
* No unwanted horizontal scrolling
* No text collision
* No buttons extending beyond the screen
* No content hidden behind system UI
* No awkward excessive whitespace

---

# 19. SOLID PRINCIPLES — MANDATORY

Follow SOLID principles throughout the codebase.

### Single Responsibility Principle

A class, widget, provider, service, or method should have one clear responsibility.

Do not create widgets responsible for:

* UI
* API calls
* Data transformation
* Navigation
* Business logic
* Validation
* State management

all inside one massive class.

Separate responsibilities appropriately.

---

# 20. SEPARATION OF CONCERNS

Keep responsibilities separated.

UI should primarily handle:

* Presentation
* User interaction
* Rendering
* UI state representation

Business logic should remain in the appropriate:

* ViewModel
* Provider
* Controller
* Use case
* Service
* Repository

depending on the existing project architecture.

Networking/API calls should not be unnecessarily embedded directly inside UI widgets.

Do not place large business-logic methods inside `build()`.

---

# 21. KEEP WIDGETS SMALL

Avoid extremely long widget files.

A screen should NOT become a single massive widget containing hundreds of lines of nested UI.

If a screen contains multiple logical sections, extract them.

For example:

```text
Screen
 ├── HeaderSection
 ├── SummarySection
 ├── ContentSection
 ├── ActionSection
 └── FooterSection
```

Create reusable widgets when they improve:

* Readability
* Reusability
* Testing
* Maintainability
* Separation of concerns

---

# 22. METHOD LENGTH

Avoid excessively long methods.

Especially avoid:

```dart
Widget build(...)
```

containing hundreds of lines.

If a method becomes difficult to understand, identify logical responsibilities and extract them into:

* Private widgets
* Reusable widgets
* Helper methods
* Dedicated classes

Prefer clear structure over clever abstractions.

---

# 23. FILE LENGTH

Avoid unnecessarily lengthy Dart files.

A file should have a clear responsibility.

If a file becomes excessively long because it contains multiple unrelated UI sections or responsibilities, refactor it.

For example, instead of:

```text
home_page.dart
```

containing:

* Header
* Search
* Filters
* Vehicle section
* Promotions
* Recent activity
* Charging stations
* Bottom navigation
* Dialogs
* Business logic

separate meaningful sections into dedicated components.

### Important:

Do NOT split code into dozens of tiny files without reason.

The goal is **logical segregation**, not fragmentation.

---

# 24. REUSABLE COMPONENTS

Before creating a new component, search the project for an existing implementation.

Prefer shared components such as:

```text
AppButton
PrimaryButton
SecondaryButton
AppTextField
AppCard
SectionHeader
AppDialog
LoadingState
EmptyState
ErrorState
```

Do not create multiple slightly different versions of the same component.

If the same UI pattern appears in multiple places, consider extracting it into a reusable component.

---

# 25. AVOID DUPLICATION

Do not duplicate:

* UI structures
* Validation
* API handling
* Formatting
* Theme values
* Button styles
* Input styles
* Navigation logic

If the same logic appears more than once, evaluate whether it should be extracted.

Follow the principle:

> **Don't Repeat Yourself (DRY).**

But do not create abstractions merely to eliminate a few lines of code.

Abstraction should improve clarity.

---

# 26. DO NOT OVER-ENGINEER

Do not introduce:

* Unnecessary design patterns
* Unnecessary abstractions
* Excessive interfaces
* Excessive wrapper widgets
* Complex generic systems
* Additional dependencies
* New state-management architecture

unless there is a clear technical reason.

Use the simplest architecture that properly separates responsibilities.

---

# 27. STATE MANAGEMENT

Follow the existing project architecture.

Before modifying a screen:

1. Identify the current state-management solution.
2. Understand how state flows into the screen.
3. Identify the existing ViewModel/provider/controller.
4. Reuse existing patterns.
5. Avoid introducing a different state-management approach unnecessarily.

Do not rewrite state management simply because a UI change is being made.

---

# 28. BUSINESS LOGIC MUST REMAIN SEPARATE

UI work must not unnecessarily modify:

* API logic
* Authentication
* Payment logic
* Networking
* Database logic
* State management
* Business rules
* Existing feature behavior

Only modify non-UI code when required to support the UI improvement.

Understand existing architecture before making structural changes.

---

# 29. BUILD METHOD DISCIPLINE

Avoid putting calculations, API calls, state mutations, or expensive operations inside:

```dart
build()
```

The `build()` method should primarily describe UI.

Do not perform unnecessary work every time Flutter rebuilds a widget.

---

# 30. THEME & DESIGN TOKENS

Centralize design-system values.

Use theme/design tokens for:

* Colors
* Typography
* Border radii
* Component styles
* Elevation
* Consistent spacing tokens where appropriate

Do not scatter design values throughout the application.

However:

> **Do not use centralized constants as an excuse to create rigid responsive layouts.**

A design token is appropriate for a consistent visual rule.

A fixed number used to force a layout into position is not.

---

# 31. BUTTON STATES

Buttons must support appropriate states:

* Default
* Pressed
* Disabled
* Loading
* Success/error feedback where required

States should remain visually simple.

Do not use gradients, glow effects, or excessive animation to communicate state.

---

# 32. INPUT STATES

Inputs should support:

* Default
* Focused
* Filled
* Error
* Disabled
* Loading where applicable

Validation should be clear and understandable.

Do not rely exclusively on color to communicate errors.

---

# 33. LIST & SCREEN STATES

Where applicable, support:

* Loading
* Loaded
* Empty
* Error
* Refreshing
* Retry

Keep these states visually simple and consistent.

Do not create different loading/empty/error designs for every screen unless there is a genuine UX reason.

---

# 34. ICONS

Icons must be simple and consistent.

Avoid:

* Mixing unrelated icon styles
* Oversized decorative icons
* Excessive icon containers
* Icons used purely for decoration

Use icons when they improve:

* Navigation
* Understanding
* Recognition
* Interaction

---

# 35. ANIMATION RULES

Animations are allowed but must be purposeful.

Use animation to communicate:

* Navigation
* State changes
* Loading
* Feedback
* User interaction

Preferred:

* Fade
* Scale
* Slide
* Subtle page transitions
* Small micro-interactions

Avoid:

* Constant floating animations
* Excessive bouncing
* Glowing animations
* Continuous background motion
* Large parallax effects
* Animating every element

### Rule:

> **If an animation does not improve usability or feedback, remove it.**

Respect reduced-motion preferences where applicable.

---

# 36. ACCESSIBILITY

Do not sacrifice accessibility for visual design.

Ensure:

* Sufficient color contrast
* Readable text
* Appropriate touch targets
* Semantic widgets
* Accessible labels
* Keyboard/accessibility support where relevant
* Clear focus states
* Meaningful icons and labels

Do not rely on color alone to communicate important information.

Also consider:

* Large accessibility text
* Screen readers
* Dynamic content
* Localization
* Different device aspect ratios

---

# 37. COLOR RULE — NO RANDOM VALUES

Do not introduce random colors.

Avoid:

```dart
Color(0xFF123456)
```

throughout individual widgets.

Use the established project theme.

If a new color is genuinely required, add it intentionally to the design system instead of introducing a one-off color.

---

# 38. NO HARDCODED POSITIONING

Avoid using fixed coordinates to position UI.

Do not attempt to solve layouts using:

```dart
Positioned(
  left: 37,
  top: 142,
)
```

unless the design genuinely requires controlled positioning inside a constrained layout.

Prefer normal Flutter layout mechanisms:

* Row
* Column
* Stack when necessary
* Flex
* Expanded
* Flexible
* Align
* Center
* Padding
* Constraints
* LayoutBuilder

The UI should naturally adapt rather than being manually positioned.

---

# 39. SCREEN REVIEW STANDARD

Whenever modifying a screen, ask:

### Layout

* Is the hierarchy obvious?
* Is the content easy to scan?
* Is spacing consistent?
* Is the layout responsive?
* Is anything unnecessarily fixed?

### Visual design

* Are there unnecessary gradients?
* Are there unnecessary shadows?
* Are corners excessively rounded?
* Are there unnecessary cards?
* Are colors consistent?

### UX

* Is the primary action obvious?
* Are loading/error/empty states handled?
* Is the interaction intuitive?

### Engineering

* Is the widget too large?
* Is the file too long?
* Is business logic mixed with UI?
* Is there duplicated code?
* Are there magic numbers?
* Are responsibilities properly separated?

### Responsiveness

* Does it work on small screens?
* Does it work on large screens?
* Does it work with larger text?
* Can content overflow?
* Are dimensions unnecessarily fixed?

### Accessibility

* Is text readable?
* Are touch targets appropriate?
* Is sufficient contrast maintained?

---

# 40. SIMPLICITY TEST

Before adding any visual element, ask:

> **Does this improve usability, hierarchy, readability, consistency, or brand recognition?**

If the answer is **no**, do not add it.

Before keeping an existing visual effect, ask the same question.

If it does not provide meaningful value, simplify or remove it.

---

# 41. CODE SIMPLICITY TEST

Before adding code, ask:

> **Can this be implemented more simply without reducing maintainability or functionality?**

Before creating a new abstraction, ask:

> **Does this abstraction genuinely improve separation, reuse, or readability?**

Before keeping a large widget, ask:

> **Does this widget have one clear responsibility?**

Before using a fixed dimension, ask:

> **Will this layout behave correctly on different screen sizes and accessibility settings?**

---

# 42. DO NOT OVER-CORRECT

"Minimal" does NOT mean:

* Boring
* Outdated
* Completely flat
* Unstyled
* Removing all animations
* Removing all visual hierarchy
* Removing brand identity

The goal is:

> **Minimal + Modern + Polished**

Maintain the application's brand identity while eliminating unnecessary visual complexity.

---

# 43. FINAL UI AUDIT

Before completing UI work, search the project for:

```text
LinearGradient
RadialGradient
SweepGradient
BoxShadow
BorderRadius
Color(
SizedBox
EdgeInsets
Container(
Positioned(
Animated
BackdropFilter
BackdropBlur
```

Do not blindly remove every occurrence.

Review each occurrence and determine whether it is:

1. Intentional
2. Responsive
3. Consistent
4. Necessary
5. Maintainable

Remove or refactor unnecessary implementations.

---

# 44. FINAL RESPONSIVENESS AUDIT

Before declaring a screen complete, verify:

### Width

* No unnecessary fixed widths
* No horizontal overflow
* Content adapts to available width

### Height

* No unnecessary fixed heights
* Content can grow naturally
* Keyboard does not hide important content

### Spacing

* No rigid spacing assumptions
* No arbitrary magic numbers
* Spacing remains visually balanced across devices

### Typography

* No text clipping
* No unexpected overflow
* Supports accessibility text scaling

### Images

* No distortion
* No unexpected cropping
* Responsive sizing

### Controls

* Buttons remain usable
* Inputs remain accessible
* Touch targets remain appropriate

---

# 45. FINAL ENGINEERING AUDIT

Before completing a task, verify:

* No unnecessarily large widget
* No unnecessarily large Dart file
* No duplicated UI
* No duplicated business logic
* No unnecessary abstractions
* No magic-number positioning
* No unnecessary fixed dimensions
* No business logic inside presentation widgets
* No API calls directly inside UI where the architecture separates networking
* Existing architecture is respected
* SOLID principles are reasonably followed
* Components have clear responsibilities
* Reusable components are used appropriately

---

# 46. DO NOT BREAK EXISTING FUNCTIONALITY

UI modernization must not unintentionally break existing functionality.

Before modifying existing code:

1. Understand the current behavior.
2. Identify dependencies.
3. Identify state flow.
4. Identify navigation.
5. Identify API dependencies.
6. Make the smallest safe change.
7. Verify the affected feature afterward.

Do not rewrite functioning code simply because it could be implemented differently.

---

# 47. IMPLEMENTATION WORKFLOW

Whenever asked to modify UI, follow this process.

## Phase 1 — Inspect

Inspect:

* Existing screen
* Existing widgets
* Theme
* State management
* ViewModels/providers
* Services
* Repositories
* Navigation
* Existing reusable components

## Phase 2 — Identify Problems

Look for:

* Gradients
* Excessive shadows
* Excessive rounded corners
* Visual noise
* Hardcoded dimensions
* Magic numbers
* Duplicated UI
* Long widgets
* Long files
* Mixed responsibilities
* Poor responsive behavior

## Phase 3 — Plan

Determine:

* What should remain
* What should be simplified
* What should become reusable
* What should be made responsive
* What should be separated

Do not immediately start rewriting everything.

## Phase 4 — Implement

Implement the smallest clean solution that satisfies the requirement.

## Phase 5 — Refactor

If the implementation creates:

* Long methods
* Long widgets
* Duplicate code
* Mixed responsibilities

refactor before completing the task.

## Phase 6 — Test

Verify:

* Small phone
* Normal phone
* Large phone
* Tablet
* Large text
* Loading state
* Empty state
* Error state
* Keyboard interaction
* Navigation

## Phase 7 — Final Audit

Perform both:

**UI/UX audit**

and

**engineering/code-quality audit**

before considering the task complete.

---

# 48. GOLDEN RULES

### UI

> **The interface should look intentionally simple, not accidentally plain.**

### Visual effects

> **Content and functionality come first. Visual effects come second.**

### Responsiveness

> **Never force a responsive layout with arbitrary fixed dimensions.**

### Spacing

> **Do not use magic numbers to force alignment. Fix the layout structure instead.**

### Architecture

> **One component, one clear responsibility.**

### Code quality

> **Prefer small, focused, reusable components over giant widgets and lengthy files.**

### SOLID

> **Separate responsibilities instead of putting UI, business logic, networking, and data processing into the same class.**

### Maintainability

> **Write code that another developer can understand and safely modify.**

### Final principle

> **When in doubt, simplify the UI and simplify the code.**
