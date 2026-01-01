# Change: Add color foundation

## Why

rice installs tools but doesn't rice them. Each tool uses its own default colors, resulting in a visually incoherent terminal. To earn the "rice" name, we need coordinated aesthetics.

Color is the foundation of terminal ricing. Without a color system, we can't have themes, and without themes, we're just a package installer with opinions.

This is the keystone for v0.2.0 and everything that follows (theme switching, terminal configs, export/import).

## What Changes

- **ADDED** Color palette system based on base16 architecture (16 semantic colors)
- **ADDED** Default theme: "rice-dark" (a custom dark palette)
- **ADDED** Color configuration files for all rice-managed tools:
  - bat (syntax highlighting)
  - lsd (file listing colors)
  - fzf (finder colors)
  - delta (git diff colors)
  - helix (editor theme)
  - tmux (status bar, borders)
  - p10k (prompt colors)
  - lf (file manager colors)
- **ADDED** `~/.config/rice/theme/` directory for theme storage
- **ADDED** `rice theme` command (initially just shows current theme)

## Impact

- Affected specs: `theming` (new capability)
- Affected code: `lib/config.sh`, `configs/*`, new `lib/theme.sh`
- Affected configs: All tool configs updated with color variables

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Color system | base16 | Industry standard, 16 colors map to terminal palette, huge ecosystem of existing themes we can adapt |
| Default theme | Custom "rice-dark" | Ship our own identity, not someone else's palette |
| Theme storage | `~/.config/rice/theme/` | Keeps themes separate from tool configs |
| Initial scope | Single theme, no switching | Get the architecture right before adding complexity |

## Out of Scope (v0.3.0+)

- Theme switching (`rice theme set gruvbox`)
- Multiple bundled themes
- Theme preview
- User-created themes
