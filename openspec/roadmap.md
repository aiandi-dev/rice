# Roadmap

Development roadmap from v0.1.0 (current) to v1.0.0 (MVP terminal ricer).

## Vision

rice is called "rice" but currently doesn't deliver on terminal ricing. It's a dev environment bootstrapper - it installs tools and configs, but doesn't provide the aesthetic customization that defines ricing.

**The gap:** Traditional ricing is about making your terminal *yours* - coordinated colors, unified themes, visual cohesion. rice v1.0.0 will deliver on that promise while staying true to our "no GUI" philosophy.

**The humor:** We're called rice but we'll never do desktop ricing. Terminal only. That's the joke, and we're committing to it.

---

## Current State (v0.1.0)

- Installs tools: shell, editor, CLI replacements, dev tools
- Deploys configs: zshrc, tmux.conf, helix config, lf config, aliases
- Idempotent one-time setup
- Debian support only

**What's missing:**

| Aspect | Current | True Terminal Rice |
|--------|---------|-------------------|
| Colors | Whatever defaults | Coordinated color scheme across all tools |
| Themes | p10k lean preset | Selectable themes, consistent palette |
| Prompt | Fixed p10k config | Customizable segments, styles |
| Fonts | "Install a nerd font" | Font recommendation/detection |
| Terminal | Not touched | Config for common terminal emulators |
| Cohesion | Tools work | Tools look unified |
| User choice | Opinionated, no choice | Opinionated *defaults*, with theme selection |

---

## Milestones

### v0.2.0 - Color Foundation

The keystone release that makes everything else possible.

- Introduce a color palette system (base16 or similar)
- Apply consistent colors to: bat, lsd, fzf, delta, helix, tmux, p10k
- Ship 1 default theme ("rice dark")

### v0.3.0 - Theme System

- Add `rice theme` command to switch palettes
- Bundle 3-5 curated themes (gruvbox, catppuccin, nord, tokyo-night)
- Themes propagate to all configured tools automatically

### v0.4.0 - Prompt Customization

- p10k segment configuration via rice
- Predefined prompt styles (minimal, full, powerline)
- `rice prompt` command

### v0.5.0 - Terminal Emulator Configs

- Generate configs for: alacritty, kitty, wezterm, ghostty
- Theme-aware (matches current rice theme)
- Font recommendations baked in

### v0.6.0 - Platform Expansion

- Ubuntu support
- Fedora support
- Arch support

### v0.7.0 - macOS Support

- Homebrew-based installation
- iTerm2/Terminal.app color scheme export

### v0.8.0 - Polish & Refinement

- `rice export` - export your config as shareable dotfiles
- `rice import` - import someone else's rice
- Theme preview in terminal

### v0.9.0 - Community & Docs

- Theme gallery/contribution system
- Full documentation site

### v1.0.0 - MVP Terminal Ricer

- Stable API
- All platforms working
- The promise delivered: one command, beautiful terminal

---

## Principles

These guide all roadmap decisions:

1. **Color is the foundation** - Everything else (themes, terminal configs, exports) depends on a solid color system
2. **Cohesion over features** - A unified look across 5 tools beats 10 tools that don't match
3. **Opinionated defaults, optional choice** - Ship beautiful defaults, let users customize if they want
4. **Terminal only** - No GUI, no desktop. That's the joke.
5. **One command** - The install experience stays simple regardless of features added

---

## Non-goals

Things we explicitly won't do:

- Desktop ricing (window managers, status bars, etc.)
- GUI applications
- Excessive configurability (we make choices so you don't have to)
- Plugin systems or extensibility frameworks
