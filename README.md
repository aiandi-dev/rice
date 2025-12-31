# rice

Opinionated terminal environment for headless servers. One command sets up a complete modern shell.

```bash
curl -fsSL https://raw.githubusercontent.com/pentaxis93/rice/main/install.sh | bash
```

## What You Get

**Shell**: zsh + oh-my-zsh + powerlevel10k with instant prompt

**Editor**: helix (modal, tree-sitter built-in, zero config)

**Tools**:
- `fd`, `rg`, `bat`, `lsd`, `fzf` - modern Unix replacements
- `zoxide` - smarter cd with frecency
- `atuin` - searchable shell history
- `lazygit`, `delta`, `gh` - Git workflow
- `lf` - terminal file manager
- `tmux` - terminal multiplexer

**Runtimes**: cargo, go, bun, uv

## Philosophy

1. **Opinionated** - We make choices so you don't have to
2. **Idempotent** - Run it N times, get the same result
3. **Minimal** - Only what's useful on servers
4. **Transparent** - Read the scripts, understand what happens

## Commands

```bash
rice          # Install or update
rice doctor   # Check health
rice status   # Show installed components
rice update   # Fetch latest and re-run
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `RICE_YES=1` | Skip prompts (automation) |
| `RICE_VERBOSE=1` | Detailed output |
| `RICE_SKIP_SHELL_CHANGE=1` | Don't change default shell |
| `GITHUB_TOKEN` | Avoid API rate limits |

## Version Policy

rice installs the **latest stable release** of each tool. Versions are fetched at runtime and verified against upstream checksums.

To pin a specific version, create `~/.config/rice/version_overrides`:
```
HELIX_VERSION=25.01
LAZYGIT_VERSION=0.44.1
```

## Customization

rice deploys configs to `~/.config/rice/`. Customize your shell in `~/.zshrc.local` (sourced automatically, not overwritten by rice).

## Supported Platforms

- **Debian 12+**
- **Ubuntu 22.04+**

## Testing

```bash
# Docker smoke test
docker build -t rice-test -f test/docker/Dockerfile.debian .
docker run --rm rice-test
```

## Uninstall

```bash
# Remove rice-managed configs
rm -rf ~/.config/rice

# Remove tools installed to ~/.local/bin
rm -rf ~/.local/bin/{hx,lazygit,delta,lf,zoxide}

# Remove runtimes (optional)
rm -rf ~/.cargo ~/.bun ~/.atuin
sudo rm -rf /usr/local/go

# Remove shell customizations
rm -rf ~/.oh-my-zsh ~/.p10k.zsh

# Change shell back to bash
chsh -s /bin/bash
```

## License

MIT
