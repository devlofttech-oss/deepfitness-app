---
name: Obsidian Kinetic
colors:
  surface: '#121315'
  surface-dim: '#121315'
  surface-bright: '#38393b'
  surface-container-lowest: '#0d0e10'
  surface-container-low: '#1b1c1e'
  surface-container: '#1f2022'
  surface-container-high: '#292a2c'
  surface-container-highest: '#343537'
  on-surface: '#e3e2e5'
  on-surface-variant: '#cbc7aa'
  inverse-surface: '#e3e2e5'
  inverse-on-surface: '#303033'
  outline: '#959277'
  outline-variant: '#494831'
  surface-tint: '#d3cb00'
  primary: '#ffffff'
  on-primary: '#343200'
  primary-container: '#f1e800'
  on-primary-container: '#6b6700'
  inverse-primary: '#656100'
  secondary: '#c2c6d1'
  on-secondary: '#2c3139'
  secondary-container: '#424750'
  on-secondary-container: '#b1b5c0'
  tertiary: '#ffffff'
  on-tertiary: '#003737'
  tertiary-container: '#97f2f2'
  on-tertiary-container: '#007071'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#f1e800'
  primary-fixed-dim: '#d3cb00'
  on-primary-fixed: '#1e1c00'
  on-primary-fixed-variant: '#4c4900'
  secondary-fixed: '#dee2ee'
  secondary-fixed-dim: '#c2c6d1'
  on-secondary-fixed: '#171c24'
  on-secondary-fixed-variant: '#424750'
  tertiary-fixed: '#97f2f2'
  tertiary-fixed-dim: '#7ad5d5'
  on-tertiary-fixed: '#002020'
  on-tertiary-fixed-variant: '#004f50'
  background: '#121315'
  on-background: '#e3e2e5'
  surface-variant: '#343537'
typography:
  display-lg:
    fontFamily: Barlow Condensed
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 52px
  display-lg-mobile:
    fontFamily: Barlow Condensed
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg:
    fontFamily: Barlow Condensed
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Barlow Condensed
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Barlow Condensed
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Barlow Condensed
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Barlow Condensed
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Barlow Condensed
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system is engineered specifically for active gym environments, where users interact with screens under harsh overhead lighting, during heavy exertion, or between timed intervals. The aesthetic is clean, athletic, and strictly functional—drawing from high-contrast industrial minimalism. 

The emotional tone balances focused intensity, physical clarity, and absolute utilitarian precision. By removing extraneous visual artifacts (no decorative gradients, no neon glows, and no generic stock photography), the system directs 100% of the user's cognitive bandwidth toward tracking sets, heart rates, class bookings, and progressive overload. High-contrast typography paired with deep, near-black tactical canvas layers creates immediate scannability from arm's length or across a gym bench.

## Colors

The palette is built upon pure utilitarian hierarchy, anchored in deep dark mode to minimize battery consumption and eye strain in dimly lit weight rooms.

- **Canvas & Backgrounds**: Base background is `#0B0C0E`. Elevated cards, sheets, and bottom navigation draw from `#121417` and `#181B20`.
- **Primary Accent**: Energetic athletic yellow (`#FFF500`). This accent is deliberately scarce: restricted solely to primary affirmative action buttons, active tab indicators, and dynamic telemetry/progress rings. It is never used decoratively or across large flat surfaces.
- **Structural Outlines**: `#1E232B` forms the subtle, crisp boundaries for cards, dividers, and input housings.
- **Typography & Content**:
  - Primary text and essential numeric metrics: `#FFFFFF` (100% stark white) for glare-resistant legibility.
  - Secondary metadata, labels, and timestamps: `#94A3B8`.
  - Inactive controls, placeholders, and structural guidelines: `#64748B`.
- **Feedback & Semantics**: Error alerts use `#EF4444`, while warnings employ `#F59E0B`. These colors are stripped of glow and applied purely as flat, solid badges or text.

## Typography

Typography establishes an athletic and disciplined hierarchy using two complementary typefaces:

1. **Barlow Condensed**: Used for all headings, key performance numerals (reps, sets, timers, weights), metric tracking, and compact data badges. Its condensed letterforms provide maximum screen economy on handheld devices, allowing large, bold metrics to sit comfortably without premature line wrapping.
2. **Inter**: Used for all reading body copy, transaction lines, descriptions, and user inputs. Its neutral, highly legible grotesque characteristics ensure rapid comprehension under moving conditions.

Letter spacing on condensed headings and labels is set to uppercase with a slight positive tracking (`+0.04em` to `+0.06em`) to preserve legibility when viewed in motion or under vibration.

## Layout & Spacing

The layout system centers on a mobile-first fluid vertical scroll, structured across a 4-column grid on mobile screens (expanding to 8 columns on tablet devices). 

- **Edge Margins & Gutters**: Outer canvas margin is strictly `1rem` (16px), giving maximum screen real estate to interactive targets while preventing accidental edge strikes during movement. Internal card gutters maintain `1rem` consistency.
- **Touch Ergonomics & Spacing**: All actionable items observe a strict 48px minimum bounding box, padded with `space-md` or `space-sm` internals to protect against miss-taps caused by sweaty fingers or workout exhaustion.
- **Rhythm**: Element stacks and data rows follow an 8pt base modular rhythm (`space-xs` = 4px, `space-sm` = 8px, `space-md` = 16px, `space-lg` = 24px, `space-xl` = 32px).

## Elevation & Depth

This system intentionally rejects ambient blur shadows, drop shadows, and glowing lights. In bright gym lighting, soft blur shadows wash out and reduce contrast. Depth is achieved exclusively through **tonal layering** and **low-contrast borders**:

- **Ground (Level 0)**: Canvas background `#0B0C0E`.
- **Cards & Surfaces (Level 1)**: Flat `#121417`, demarcated with a 1px solid border of `#1E232B`.
- **Floating Modals & Sheets (Level 2)**: Flat `#181B20`, bordered with a 1px solid `#28303C` border to separate from underlying Level 1 components.
- **Active State Highlights**: Defined solely by solid strokes or background fills, never by outer glow or blurred diffusion.

## Shapes

The shape system employs consistent, refined rounded geometry (`roundedness: 2` / 8px radius for base components) to soften the intense dark theme while maintaining a structural, athletic footprint:

- **Standard Cards & Input Containers**: 8px (`0.5rem`).
- **Modal Sheets & Workout Overview Panels**: 16px (`1rem` / `rounded-lg`) along top corners.
- **Badges, Numeric Chips & Floating Action Buttons**: Full pill-shaped rounding for immediate semantic distinction from data containers.
- **Dividers & Strokes**: Precise 1px flat solid lines without bevels or soft gradients.

## Components

- **Buttons**:
  - *Primary CTA*: Full-width or oversized (minimum height 52px), solid athletic yellow background (`#FFF500`), high-contrast near-black bold text (`#0B0C0E`), uppercase `label-lg` typography. Pressed state: `#E6DC00`.
  - *Secondary / Utility*: Dark surface (`#121417`), 1px solid border (`#1E232B`), stark white text (`#FFFFFF`).
  - *Tertiary / Ghost*: Transparent background, `#94A3B8` text, transitioning to `#FFFFFF` on press.
- **Cards & Metrics**:
  - Dark container (`#121417`) enclosed by a 1px `#1E232B` border.
  - Large Barlow Condensed display numbers (`#FFFFFF`) coupled with compact uppercase labels (`#94A3B8`).
- **Telemetry & Progress Rings**:
  - Base inactive track: 1px to 4px flat track in `#1E232B`.
  - Active track: Solid `#FFF500` stroke without stroke caps or outer glows.
- **Chips & Filters**:
  - Unselected: Background `#121417`, border 1px `#1E232B`, text `#94A3B8`.
  - Active: Background `#FFF500`, border 1px `#FFF500`, text `#0B0C0E` in semi-bold condensed tracking.
- **Input Fields**:
  - Height 52px, background `#121417`, border 1px solid `#1E232B`, placeholder text `#64748B`, active input text `#FFFFFF`.
  - Focused state: 1px solid `#FFF500` without ambient drop shadow.
- **Checkboxes & Radios**:
  - Bounding target 48x48px with centered 20px glyph box. Unchecked: 1px border `#64748B`. Checked: Solid fill `#FFF500` with black check/dot indicator.
- **Iconography**:
  - Athletic, monoline, geometric icons with a consistent 2px stroke width. Outlines in `#94A3B8` (inactive) or `#FFF500` (active). Solid photography is replaced with structural vectors or SVG telemetry paths.