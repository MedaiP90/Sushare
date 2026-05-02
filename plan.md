# Liquid Glass Polish – Implementation Plan

---

## 1. Fix body top padding

### Problem
Pages that set an explicit `padding` on their `ListView` or `SingleChildScrollView` ignore the
`MediaQuery.padding.top` value injected by `GlassAwareScaffold`. This means their content starts
too close to the top (behind the status bar / glass title pill) when in liquid glass mode.

Affected pages (explicit top padding that overrides MediaQuery):
- `sessions_page.dart` – `EdgeInsets.fromLTRB(16, 8, 16, 100)`
- `restaurants_page.dart` – `EdgeInsets.all(16)`
- `new_session_page.dart` – `EdgeInsets.all(24)`
- `join_session_page.dart` – `EdgeInsets.all(24)`
- `settings_page.dart` – varies

### Fix – `glass_aware_scaffold.dart`
Change the current approach from "inject into MediaQuery padding" to "wrap body in a Padding widget
AND zero-out MediaQuery padding.top so inner SafeArea widgets don't double-count":

```dart
// glass mode body construction:
final paddedBody = MediaQuery(
  data: MediaQuery.of(context).copyWith(
    padding: MediaQuery.paddingOf(context).copyWith(top: 0), // zero top so SafeArea doesn't re-add
  ),
  child: Padding(
    padding: EdgeInsets.only(top: topInset),
    child: body,
  ),
);
```

**Why**: The `Padding(top: topInset)` pushes all content types (ListView, Column, Stack, etc.)
down uniformly, regardless of whether they have explicit padding. Setting MediaQuery `padding.top`
to 0 prevents nested `SafeArea` from adding an additional status-bar gap on top of ours.

### Also fix – every page with an explicit scroll-view padding
For pages that read `MediaQuery.paddingOf(context).top` explicitly (e.g. to compute padding),
they will now receive 0 (since we zeroed it). Their explicit padding is already offset by the
outer `Padding`. This means no page-level change is required for pages that ONLY use explicit
constant padding — the outer `Padding` does the job. Pages that read MediaQuery top dynamically
need to be reviewed to ensure they don't add a redundant top inset.

---

## 2. App bar button spacing

### Problem
In glass mode, the back button, glass title pill, and action buttons are too close together and
sit too close to the left/right screen edges. `AppBar`'s default horizontal margins are designed
for Material buttons, not for freestanding glass pill widgets.

### Fix – `glass_aware_app_bar.dart` `_GlassBar.build()`

**Leading button**: Wrap in `Padding(left: 8)` and increase `leadingWidth` to 60:
```dart
leading: effectiveLeading != null
    ? Padding(
        padding: const EdgeInsets.only(left: 8),
        child: effectiveLeading,
      )
    : null,
leadingWidth: 60,
```

**Action buttons**: Map each action to add symmetric horizontal spacing. The last action gets
extra right padding to clear the screen edge:
```dart
actions: actions == null
    ? null
    : [
        for (int i = 0; i < actions!.length; i++)
          Padding(
            padding: EdgeInsets.only(
              left: 4,
              right: i == actions!.length - 1 ? 12 : 4,
            ),
            child: actions![i],
          ),
      ],
```

**Title pill**: The `GlassContainer` title already has internal horizontal padding. No extra
change needed, but `titleSpacing` can be set to 8 if it feels too close to the leading.

---

## 3. Home shell – use `GlassAwareScaffold`

### Problem
`home_page.dart` builds its own `Scaffold` directly instead of using `GlassAwareScaffold`.
This means the glass-mode properties (`extendBody: true`, consistent scaffold behaviour) are
hand-coded there rather than delegated to the shared widget.

### Fix – `home_page.dart`

Replace both `Scaffold(...)` instances (glass path and material path) with a single
`GlassAwareScaffold`:

```dart
return GlassAwareScaffold(
  body: child,
  bottomNavigationBar: isGlass
      ? DecoratedBox(
          decoration: ..., // existing shadow
          child: GlassBottomBar(...), // existing glass bar
        )
      : NavigationBar(...), // existing material bar
);
```

Since `home_page.dart` has **no app bar**, `GlassAwareScaffold` with `appBar: null` computes
`topInset = statusBarHeight + 0 = statusBarHeight`. Because this equals the original system
`MediaQuery.padding.top`, the child pages' own `GlassAwareScaffold` reads the same value it
always did and continues computing their own `topInset = statusBarHeight + kToolbarHeight`
correctly. No double-padding occurs.

`extendBody: true` (already added by the linter) means the child page bodies extend behind the
glass bottom bar, which is the desired see-through effect.

Remove the `styleModeProvider` watch that is currently used only to switch between the two
`Scaffold` branches — the new code can still watch it to conditionally build the bottom bar, but
the scaffold wrapping no longer needs the branch.

---

## 4. FABs near the bottom navigation bar

### Problem
When a page has both floating action buttons and a bottom navigation bar, the FABs float in the
bottom-right corner, far from the navigation. The user wants the FABs to live **alongside** the
navigation bar: icon-only, at the same vertical level, with the nav tabs shifting to make room.

### Affected pages
| Page | FABs | Bottom nav owner |
|------|------|-----------------|
| `sessions_page.dart` | join (icon), new (extended) | `home_page.dart` |
| `restaurants_page.dart` | add (extended) | `home_page.dart` |
| `personal_order_content.dart` | template, menu, custom | `session_shell_page.dart` |
| `merged_order_content.dart` | send / open-round | `session_shell_page.dart` |

### Design
At the bottom of the screen the layout should look like:

```
┌────────────────────────────────────────────────────────┐
│  [●] [●]  │  Tab 1  │  Tab 2  │  Tab 3  │             │
│  FABs     │    Navigation tabs (glass bar)             │
└────────────────────────────────────────────────────────┘
```

The FABs are icon-only glass circles placed on the **left** of the glass bottom bar. The nav bar
takes the remaining width via `Expanded`.

### Implementation approach

#### Step A – Bottom actions provider
Create `lib/core/style/bottom_actions_provider.dart`:

```dart
// A page can push its glass FABs into this notifier; the shell reads from it.
final bottomActionsProvider =
    StateNotifierProvider<BottomActionsNotifier, List<Widget>>(
      (ref) => BottomActionsNotifier(),
    );

class BottomActionsNotifier extends StateNotifier<List<Widget>> {
  BottomActionsNotifier() : super([]);
  void setActions(List<Widget> actions) => state = actions;
  void clear() => state = [];
}
```

#### Step B – Child pages inject actions (glass mode only)
In `sessions_page.dart`, `restaurants_page.dart`, `personal_order_content.dart`, and
`merged_order_content.dart`, when `isGlass == true`, register the icon-only FABs via the
provider in a `WidgetsBinding.addPostFrameCallback` inside `build()`, and clear them in
`dispose()`.

All icon-only FABs use `GlassButton` (circle, 50×50):
```dart
GlassButton(
  icon: Icon(Icons.qr_code_scanner, color: iconColor),
  onTap: ...,
  useOwnLayer: true,
  settings: glassSettings,
)
```

Extended FABs (e.g. "New Table") become icon-only circles — the label is dropped.

In glass mode, **do not** use `Scaffold.floatingActionButton`. Set it to `null` and rely on the
bottom bar to display the actions.

#### Step C – Shell pages render the combined bottom bar
In `home_page.dart` and `session_shell_page.dart`, consume `bottomActionsProvider` and render:

```dart
bottomNavigationBar: isGlass
    ? DecoratedBox(
        decoration: ...,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Left section: icon-only glass FABs
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in actions) ...[a, const SizedBox(width: 8)],
                  ],
                ),
              ),
            // Right section: glass nav tabs take remaining width
            Expanded(
              child: GlassBottomBar(
                glassSettings: ...,
                selectedIndex: ...,
                onTabSelected: ...,
                tabs: ...,
              ),
            ),
          ],
        ),
      )
    : NavigationBar(...),
```

The `GlassBottomBar` naturally adapts its tab widths to the available `Expanded` space.

#### Step D – Existing `floatingActionButton` wiring
- In glass mode: set `floatingActionButton: null` in all affected pages.
- In material mode: keep existing `FloatingActionButton` / `FloatingActionButton.extended`
  (no change needed).

---

## 5. Restaurant detail page – liquid glass theme

### Problem
`restaurant_detail_page.dart` uses a raw `Scaffold` with `SliverAppBar` and is not wired to
`styleModeProvider` at all. In liquid glass mode it looks entirely Material.

### Changes

#### Imports
Add `liquid_glass_widgets`, `app_style.dart`, `glass_aware_app_bar.dart`.

#### Null / loading / error states
Replace `Scaffold(appBar: AppBar(), body: ...)` with `GlassAwareScaffold(appBar: GlassAwareAppBar(), body: ...)`.

#### Main data state – `SliverAppBar`
The `SliverAppBar` drives the collapsing hero image header; keep it but make it glass-aware:

```dart
SliverAppBar(
  expandedHeight: 200,
  pinned: true,
  centerTitle: true,
  backgroundColor: isGlass ? Colors.transparent : null,
  surfaceTintColor: isGlass ? Colors.transparent : null,
  elevation: isGlass ? 0 : null,
  flexibleSpace: FlexibleSpaceBar(
    centerTitle: true,
    title: isGlass
        ? GlassContainer(
            useOwnLayer: true,
            settings: glassBarButtonSettings(isLight),
            shape: const LiquidRoundedSuperellipse(borderRadius: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(restaurant.name, style: TextStyle(color: iconColor, fontSize: 16, fontWeight: FontWeight.w600)),
          )
        : Text(restaurant.name),
    collapseMode: CollapseMode.parallax,
    background: ..., // unchanged
  ),
  actions: [
    if (isGlass)
      Builder(
        builder: (ctx) => GlassIconButton(
          icon: Icon(Icons.more_vert, size: 20, color: iconColor),
          onPressed: () => _showRestaurantMenu(ctx, ref, restaurant, l10n),
          useOwnLayer: true,
          size: 36,
          settings: glassBarButtonSettings(isLight),
        ),
      )
    else
      PopupMenuButton<String>(...), // unchanged
  ],
),
```

Add `_showRestaurantMenu` method (same pattern as `_showActionsMenu` in session_shell_page):
extract `_restaurantMenuItems()` returning the list of edit/delete `PopupMenuItem`s, and
`_handleRestaurantMenuSelection()` with the existing confirm-dialog logic.

#### FABs
Replace the search + add FAB pair:

**Search FAB** — keep the animated expanding behaviour; in glass mode replace the
`AnimatedContainer` background colour with a `GlassContainer` wrapper (keep the inner `Row`
with close button + `TextField` unchanged, just swap the outer `BoxDecoration` for glass):

```dart
// glass mode collapsed state:
GlassButton(
  icon: Icon(Icons.search, color: iconColor),
  onTap: () => setState(() => _isSearchExpanded = true),
  useOwnLayer: true,
  settings: glassBarButtonSettings(isLight),
)

// glass mode expanded state:
GlassContainer(
  useOwnLayer: true,
  settings: glassBarButtonSettings(isLight),
  shape: const LiquidRoundedSuperellipse(borderRadius: 28),
  width: expandedSearchWidth,
  height: 56,
  child: Row(
    children: [
      GlassIconButton(icon: Icon(Icons.close, ...), onPressed: _collapseSearch, ...),
      Expanded(child: TextField(...)), // unchanged
    ],
  ),
)
```

**Add FAB** — `GlassButton(icon: Icon(Icons.add), onTap: ..., useOwnLayer: true, settings: ...)`.

#### Per-item `PopupMenuButton` in the list
Each `ListTile` has a `trailing: PopupMenuButton(...)` for edit/yummie/delete. In glass mode,
convert to a `GlassIconButton` + `showMenu` (same `Builder` pattern used elsewhere). This is
optional for a first pass — it can be marked as a follow-up since the per-item menus are less
prominent.

#### `Scaffold` wrapper
Wrap the main `Scaffold` (with the `CustomScrollView`) in glass mode awareness. Since the
`SliverAppBar` is already transparent in glass mode, the outer `Scaffold` can remain a plain
`Scaffold` (no `GlassAwareScaffold` needed for the outer shell because the `SliverAppBar`
owns the collapsing area). Add `extendBodyBehindAppBar: true` in glass mode.

---

## File change summary

| File | Changes |
|------|---------|
| `lib/ui/core/widgets/glass_aware_scaffold.dart` | Padding-based top inset + zero MediaQuery.top |
| `lib/ui/core/widgets/glass_aware_app_bar.dart` | Leading + action spacing |
| `lib/ui/pages/home/home_page.dart` | Switch to `GlassAwareScaffold`; consume `bottomActionsProvider` |
| `lib/ui/pages/home/sessions_page.dart` | Inject icon FABs via provider; clear `floatingActionButton` in glass mode |
| `lib/ui/pages/home/restaurants_page.dart` | Inject icon FABs via provider; clear `floatingActionButton` in glass mode |
| `lib/ui/pages/session/session_shell_page.dart` | Consume `bottomActionsProvider` in combined bottom bar |
| `lib/ui/pages/session/personal_order_content.dart` | Inject icon FABs via provider; clear `floatingActionButton` in glass mode |
| `lib/ui/pages/session/merged_order_content.dart` | Inject icon FABs via provider; clear `floatingActionButton` in glass mode |
| `lib/core/style/bottom_actions_provider.dart` | New file – `BottomActionsNotifier` |
| `lib/ui/pages/restaurant/restaurant_detail_page.dart` | Glass SliverAppBar, glass FABs, glass popup menu |
