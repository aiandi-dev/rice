#!/usr/bin/env bash
# rice lf preview script
# Uses bat for syntax highlighting when available

file="$1"
width="${2:-$(tput cols)}"
height="${3:-$(tput lines)}"

# Handle different file types
case "$(file --mime-type -b "$file")" in
  text/*)
    if command -v bat &>/dev/null; then
      bat --style=plain --color=always --line-range=:100 "$file"
    else
      head -100 "$file"
    fi
    ;;
  application/json)
    if command -v jq &>/dev/null; then
      jq -C . "$file" 2>/dev/null || cat "$file"
    elif command -v bat &>/dev/null; then
      bat --style=plain --color=always "$file"
    else
      cat "$file"
    fi
    ;;
  application/zip|application/x-tar|application/gzip|application/x-bzip2|application/x-xz|application/x-7z-compressed)
    if command -v atool &>/dev/null; then
      atool -l "$file"
    else
      echo "Archive: $file"
      echo "(install atool for preview)"
    fi
    ;;
  *)
    file "$file"
    ;;
esac
