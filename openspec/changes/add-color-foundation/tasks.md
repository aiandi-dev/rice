# Implementation Tasks

## 1. Theme Infrastructure
- [ ] 1.1 Create `lib/theme.sh` with color variable loading
- [ ] 1.2 Create `~/.config/rice/theme/` directory structure
- [ ] 1.3 Define base16 color variable schema (base00-base0F)
- [ ] 1.4 Create `rice-dark.sh` theme file with 16 color definitions

## 2. Tool Color Configs
- [ ] 2.1 Create bat theme (syntax highlighting)
- [ ] 2.2 Update `configs/lsd/` with color config (LS_COLORS style)
- [ ] 2.3 Update fzf colors in zshrc (FZF_DEFAULT_OPTS)
- [ ] 2.4 Update delta colors in `configs/gitconfig`
- [ ] 2.5 Create helix theme file in `configs/helix/themes/`
- [ ] 2.6 Update tmux colors in `configs/tmux.conf`
- [ ] 2.7 Update p10k colors in `configs/p10k.zsh`
- [ ] 2.8 Update lf colors in `configs/lf/lfrc`

## 3. Theme Application
- [ ] 3.1 Update `lib/config.sh` to deploy theme files
- [ ] 3.2 Source theme variables before generating tool configs
- [ ] 3.3 Add theme deployment to Phase 8 (Configuration)

## 4. rice theme Command
- [ ] 4.1 Add `theme` subcommand to install.sh
- [ ] 4.2 Implement `rice theme` (show current theme)
- [ ] 4.3 Implement `rice theme list` (list available themes)

## 5. Documentation
- [ ] 5.1 Document color system in README
- [ ] 5.2 Document theme file format for future contributors

## 6. Testing
- [ ] 6.1 Verify all tools pick up theme colors
- [ ] 6.2 Test fresh install with theme
- [ ] 6.3 Test re-run preserves theme
- [ ] 6.4 Docker smoke test with themed output
