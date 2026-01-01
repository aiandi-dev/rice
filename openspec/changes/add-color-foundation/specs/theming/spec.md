# Theming Specification

rice provides a unified color system that applies consistent colors across all managed tools.

## Design Principles

### Color Coherence
Every tool rice manages uses the same 16-color palette. When you look at your terminal, bat, fzf, helix, tmux, and your prompt all feel like they belong together.

### base16 Architecture
rice uses the base16 color system: 16 semantic colors (base00-base0F) that map to specific purposes. This is an industry standard with hundreds of existing themes that can be adapted.

### Single Source of Truth
Colors are defined once in a theme file. Tool configs reference these colors, not hardcoded values.

---

## ADDED Requirements

### Requirement: Theme directory structure
The system SHALL create and manage a theme directory for color definitions.

#### Scenario: Directory creation
- **WHEN** rice installer runs
- **THEN** create `~/.config/rice/theme/` directory
- **AND** deploy active theme to `~/.config/rice/theme/current.sh`

#### Scenario: Theme file format
- **WHEN** reading a theme file
- **THEN** source as bash variables
- **AND** expect base16 variables: `BASE00` through `BASE0F`
- **AND** expect semantic aliases: `RICE_BG`, `RICE_FG`, `RICE_ACCENT`, etc.

### Requirement: base16 color schema
The system SHALL use the base16 color architecture with 16 semantic color slots.

#### Scenario: Color variable definitions
- **WHEN** a theme is loaded
- **THEN** the following variables SHALL be defined:
  - `BASE00` - Default Background
  - `BASE01` - Lighter Background (status bars, line numbers)
  - `BASE02` - Selection Background
  - `BASE03` - Comments, Invisibles
  - `BASE04` - Dark Foreground (status bars)
  - `BASE05` - Default Foreground
  - `BASE06` - Light Foreground
  - `BASE07` - Lightest Foreground
  - `BASE08` - Red (errors, deletions)
  - `BASE09` - Orange (integers, warnings)
  - `BASE0A` - Yellow (classes, search)
  - `BASE0B` - Green (strings, success, additions)
  - `BASE0C` - Cyan (support, escape chars)
  - `BASE0D` - Blue (functions, methods)
  - `BASE0E` - Purple (keywords)
  - `BASE0F` - Brown (deprecated, embedded)

#### Scenario: Color format
- **WHEN** colors are defined
- **THEN** use 6-digit hex format without hash (e.g., `1a1b26`)
- **AND** tool configs prepend `#` as needed

### Requirement: Default theme
The system SHALL ship with a default theme called "rice-dark".

#### Scenario: Fresh installation
- **WHEN** rice is installed for the first time
- **THEN** deploy "rice-dark" theme as the active theme

#### Scenario: rice-dark palette
- **WHEN** rice-dark theme is active
- **THEN** use a dark background palette optimized for terminal readability
- **AND** provide sufficient contrast for accessibility

### Requirement: bat theme integration
The system SHALL apply theme colors to bat syntax highlighting.

#### Scenario: Theme deployment
- **WHEN** theme is applied
- **THEN** generate bat theme file at `~/.config/bat/themes/rice.tmTheme`
- **AND** set `BAT_THEME=rice` in shell configuration
- **AND** run `bat cache --build` to register theme

### Requirement: lsd color integration
The system SHALL apply theme colors to lsd file listings.

#### Scenario: Theme deployment
- **WHEN** theme is applied
- **THEN** generate lsd color config at `~/.config/lsd/colors.yaml`
- **AND** map file types to theme colors

### Requirement: fzf color integration
The system SHALL apply theme colors to fzf finder interface.

#### Scenario: Theme deployment
- **WHEN** theme is applied
- **THEN** set `FZF_DEFAULT_OPTS` with theme colors in zshrc
- **AND** configure: background, foreground, selection, border colors

### Requirement: delta color integration
The system SHALL apply theme colors to delta git diffs.

#### Scenario: Theme deployment
- **WHEN** theme is applied
- **THEN** configure delta colors in `~/.config/rice/gitconfig`
- **AND** map: plus-style (green), minus-style (red), syntax theme

### Requirement: helix theme integration
The system SHALL apply theme colors to the helix editor.

#### Scenario: Theme deployment
- **WHEN** theme is applied
- **THEN** generate helix theme at `~/.config/helix/themes/rice.toml`
- **AND** set `theme = "rice"` in helix config

### Requirement: tmux color integration
The system SHALL apply theme colors to tmux status bar and borders.

#### Scenario: Theme deployment
- **WHEN** theme is applied
- **THEN** configure tmux colors in `~/.config/rice/tmux.conf`
- **AND** map: status bar background, foreground, active/inactive window colors, border colors

### Requirement: powerlevel10k color integration
The system SHALL apply theme colors to the powerlevel10k prompt.

#### Scenario: Theme deployment
- **WHEN** theme is applied
- **THEN** configure p10k colors in `~/.p10k.zsh`
- **AND** map: directory color, git status colors, command status colors

### Requirement: lf color integration
The system SHALL apply theme colors to the lf file manager.

#### Scenario: Theme deployment
- **WHEN** theme is applied
- **THEN** configure lf colors in `~/.config/lf/lfrc`
- **AND** map: directory, executable, symlink, selection colors

### Requirement: rice theme command
The system SHALL provide a command to display current theme information.

#### Scenario: Show current theme
- **WHEN** running `rice theme`
- **THEN** display current theme name
- **AND** display color palette preview (colored blocks)

#### Scenario: List themes
- **WHEN** running `rice theme list`
- **THEN** list all available themes
- **AND** mark current theme with indicator

### Requirement: Theme persistence
The system SHALL preserve theme selection across rice updates.

#### Scenario: Re-run rice
- **WHEN** rice is re-run
- **THEN** preserve current theme selection
- **AND** regenerate tool configs with current theme colors

#### Scenario: Theme state
- **WHEN** tracking theme state
- **THEN** record active theme in `~/.config/rice/state.json`
