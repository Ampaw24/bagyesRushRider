# BagyesRUSH Rider — Claude Guidelines

## Icons

**Always use HugeIcons for all icons.** Never use `Icons.*` (Material) or `FontAwesomeIcons.*` in this project.

- Import: `import 'package:hugeicons/hugeicons.dart';`
- Usage: `Icon(HugeIcons.strokeRoundedX, ...)` — use the `strokeRounded` style prefix
- Package is already in `pubspec.yaml` as `hugeicons: ^0.0.7`

## Tech Stack

- Flutter 3.x / Dart
- Package: `com.example.delivery_boy`
- AGP 8.9.1, Kotlin 2.1.0, Gradle 8.11.1, compileSdk 36
# Flutter Responsiveness Rules (STRICT)

## No Hardcoded Layout Values

DO NOT use fixed constant values for:

* width
* height
* padding
* margin
* spacing
* font sizes
* icon sizes
* border radius
* positioned offsets

Avoid:

```dart
width: 300
height: 200
padding: EdgeInsets.all(20)
SizedBox(height: 30)
fontSize: 18
```

## Required Responsive Approach

Always use:

* MediaQuery
* LayoutBuilder
* Flexible
* Expanded
* FractionallySizedBox
* AspectRatio
* FittedBox
* Wrap
* Spacer
* constraints-based layouts

Preferred scaling patterns:

```dart
final width = MediaQuery.of(context).size.width;
final height = MediaQuery.of(context).size.height;

padding: EdgeInsets.symmetric(
  horizontal: width * 0.04,
  vertical: height * 0.015,
)
```

## Responsive Typography

* Font sizes must scale relative to screen dimensions or use responsive typography utilities.
* Avoid static text sizing.
* Ensure accessibility scaling compatibility.

## Device Compatibility

UI must support:

* small phones
* large phones
* tablets
* landscape mode
* split-screen mode
* foldables

Never assume a fixed screen size.

---

# UI/UX Standards

* Maintain consistent spacing systems.
* Use design tokens or centralized theme constants.
* Prefer adaptive layouts over scroll-heavy fixes.
* Avoid overflow-prone layouts.
* Always account for keyboard insets.
* Use SafeArea appropriately.
* Minimize widget tree depth where possible.

## Animation Rules

* Keep animations performant and subtle.
* Avoid unnecessary rebuilds during animations.
* Use const constructors only where responsiveness is unaffected.
