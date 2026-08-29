# Chat UI Kit — Minimal & Clean

A complete chat-app UI design — login, sign up, chat list, conversation,
profile, and settings — implemented twice from one shared token system:
once for the web (plain HTML/CSS/JS, framework-agnostic) and once for
Flutter. Drop either half into your own project; use both if you want the
web and mobile app to look identical.

```
chat-app-ui-kit/
├── design-tokens/
│   └── tokens.json        ← single source of truth for color/type/spacing
├── web/
│   ├── index.html         ← all 6 screens, open directly in a browser
│   ├── css/
│   │   ├── tokens.css      (CSS custom properties, incl. dark theme)
│   │   ├── base.css        (resets, font import, type utility classes)
│   │   └── components.css  (buttons, bubbles, list rows, forms, etc.)
│   └── js/
│       └── app.js         ← screen routing + demo interactivity
└── flutter/
    ├── pubspec.yaml
    └── lib/
        ├── theme/          (AppColors, AppTypography, AppTheme, ThemeController)
        ├── widgets/         (Avatar, ChatBubble, ConversationTile, AppButton, AppTextField, StatusDot)
        ├── screens/         (Login, Signup, ChatList, Chat, Profile, Settings)
        └── main.dart       ← runnable demo app
```

## Design system

- **Palette** — near-white "Paper" background, graphite "Ink" text, hairline
  "Mist" borders instead of drop shadows, and a single **Cobalt** accent
  (`#3049B5`) used for sent bubbles, primary buttons, and active states.
  Signal green / coral / amber are reserved for presence, destructive
  actions, and warnings respectively. Full light + dark values are in
  `design-tokens/tokens.json`.
- **Type** — Inter for all UI text. A monospace face (JetBrains Mono) is
  reserved *only* for timestamps, unread counters, and metadata — never
  message text — as a small precise/technical accent against the otherwise
  plain interface.
- **Signature detail** — message bubbles use a 16px radius with the corner
  on the sender's own side squared to 4px, instead of the usual speech-tail
  graphic. Sent and received bubbles are mirror images of each other.
- **Elevation** — mostly conveyed with 1px borders (`mist`), not shadows.
  A soft shadow token exists for modals/sheets only.

Change a value once in `design-tokens/tokens.json`, then mirror it in
`web/css/tokens.css` and `flutter/lib/theme/app_colors.dart` — the three
files intentionally use the same names so a find-and-replace stays easy.

## Using the web kit in a JS project

It's dependency-free HTML/CSS/JS — no build step:

1. Copy the `web/` folder's contents into your project (e.g. `public/`).
2. Open `index.html` directly, or mount its markup into your app shell.
3. If you're using React/Vue/Svelte/etc., treat `components.css` as your
   component stylesheet and port the markup in `index.html` into your
   framework's templates — the class names are already component-scoped
   (`.bubble`, `.conversation-item`, `.setting-row`, …) so this is a
   fairly mechanical conversion.
4. `app.js` shows the intended behavior (view routing, sending a message,
   dark-mode toggle, mobile back button) — reimplement the same logic in
   your framework's state model.

Resize the browser below 900px to see the mobile layout: the 3-pane shell
collapses to a single pane with a back button.

## Using the Flutter kit

1. Copy the `flutter/lib` folder (and merge `pubspec.yaml`'s dependencies)
   into your Flutter project, or run this folder standalone:
   ```
   cd flutter
   flutter pub get
   flutter run
   ```
2. Wrap your `MaterialApp` with the theme:
   ```dart
   MaterialApp(
     theme: AppTheme.light,
     darkTheme: AppTheme.dark,
     themeMode: ThemeController.mode.value, // or wire your own state
     home: const LoginScreen(),
   )
   ```
3. Pull colors anywhere with `Theme.of(context).extension<AppSemanticColors>()!`
   instead of hardcoding hex values, so both themes keep working.
4. **Fonts**: the kit assumes "Inter" and "JetBrainsMono" are bundled (see
   the commented-out `fonts:` block in `pubspec.yaml`) — either add the
   `.ttf` files, or swap the `fontFamily` constants in
   `lib/theme/app_typography.dart` for the `google_fonts` package.

## Screens included

| Screen | Web | Flutter |
|---|---|---|
| Login | `#screen-login` | `login_screen.dart` |
| Sign up | `#screen-signup` | `signup_screen.dart` |
| Chat list | `.list-pane` (part of `#screen-app`) | `chat_list_screen.dart` |
| Conversation | `.chat-pane` (part of `#screen-app`) | `chat_screen.dart` |
| Profile | `.center-pane.for-profile` | `profile_screen.dart` |
| Settings | `.center-pane.for-settings` | `settings_screen.dart` |

All conversation/message content in both demos is placeholder data — wire
it up to your own backend or state management.
