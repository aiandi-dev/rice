# rice-managed - https://github.com/pentaxis93/rice
# Powerlevel10k Configuration
# Style: Lean (clean, no background colors)
# To customize further: p10k configure

# Temporarily change options
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # Unset all configuration options
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Prompt appears instantly. Disable if you experience issues.
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

  # Use Nerd Font icons when available, fallback to unicode
  typeset -g POWERLEVEL9K_MODE=nerdfont-v3
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate

  # Lean style: no background, separators are spaces
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=

  # Add newline between prompts
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # ================================[ LEFT PROMPT ]================================
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir                     # current directory
    vcs                     # git status
  )

  # ================================[ RIGHT PROMPT ]================================
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # exit code
    command_execution_time  # last command duration
    background_jobs         # background jobs indicator
    direnv                  # direnv status
    virtualenv              # python virtualenv
    context                 # user@hostname (SSH/root only)
    time                    # current time
  )

  # ================================[ DIRECTORY ]================================
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=31
  # Shorten directory to last 3 segments
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80

  # Directory colors
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=103

  # ================================[ VCS / GIT ]================================
  # Enable gitstatus for faster git info
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  # Branch colors
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=76
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=244

  # Git icons - using Nerd Font icons
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='!'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='+'
  typeset -g POWERLEVEL9K_VCS_STASH_ICON='*'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='\u21E3'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='\u21E1'

  # Formatting
  typeset -g POWERLEVEL9K_VCS_GIT_ICON=
  typeset -g POWERLEVEL9K_VCS_GIT_GITHUB_ICON=
  typeset -g POWERLEVEL9K_VCS_GIT_GITLAB_ICON=
  typeset -g POWERLEVEL9K_VCS_GIT_BITBUCKET_ICON=

  # Show "on" before branch name for readability
  typeset -g POWERLEVEL9K_VCS_PREFIX='on '

  # Commit hash style
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_COMMITS_AHEAD_MAX_NUM=-1
  typeset -g POWERLEVEL9K_VCS_COMMITS_BEHIND_MAX_NUM=-1

  # ================================[ STATUS ]================================
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=true
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=160

  # ================================[ COMMAND EXECUTION TIME ]================================
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='took '

  # ================================[ BACKGROUND JOBS ]================================
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=70

  # ================================[ DIRENV ]================================
  typeset -g POWERLEVEL9K_DIRENV_FOREGROUND=178

  # ================================[ VIRTUALENV ]================================
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=37
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # ================================[ CONTEXT (user@host) ]================================
  # Only show in SSH sessions or as root
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=178
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%B%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND=180
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'

  # ================================[ TIME ]================================
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=66
  typeset -g POWERLEVEL9K_TIME_FORMAT='at %D{%I:%M:%S %p}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false

  # ================================[ PROMPT CHAR ]================================
  # Prompt symbol: ❯ for normal, ❮ for vi command mode
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=

  # ================================[ TRANSIENT PROMPT ]================================
  # Make previous prompts simpler
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off

  # ================================[ INSTANT PROMPT ]================================
  # This is the top of ~/.zshrc content for instant prompt
  typeset -g POWERLEVEL9K_INSTANT_PROMPT_COMMAND_LINES=1
}

# Restore original shell options
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'

# Hot reload if p10k is already loaded
(( ! $+functions[p10k] )) || p10k reload
