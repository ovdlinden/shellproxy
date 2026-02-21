#!/bin/zsh
# shellproxy - pre-computes both prompt variants for instant switching

typeset -g _sp_docker=0
typeset -g _sp_prompt_local=""
typeset -g _sp_prompt_docker=""

prompt_shellproxy() { :; }

_sp_precmd() {
    _sp_docker=0

    # Build command hash table for O(1) lookups
    _sp_cmds=()
    if [[ -n "$SHELLPROXY_COMMANDS" ]]; then
        local cmd
        for cmd in ${=SHELLPROXY_COMMANDS}; do
            _sp_cmds[$cmd]=1
        done
    fi

    # Build base (without ending)
    local raw_base
    raw_base=$(
        CURRENT_BG=''
        RETVAL=$?
        prompt_status
        prompt_context
        prompt_dir
        prompt_git
        printf '\x00%s' "$CURRENT_BG"
    )
    local base="${raw_base%$'\x00'*}"
    local saved_bg="${raw_base##*$'\x00'}"

    # Local: normal arrow with spacing
    local end_local="   %{%k%F{${saved_bg}}%}${SEGMENT_SEPARATOR}%{%f%}  "
    # Docker: cyan arrow, move back 4, print whale with cyan background and left padding
    local save=$'\e7'
    local restore=$'\e8'
    local cub4=$'\e[4D'
    local end_docker="   %{%k%F{cyan}%}${SEGMENT_SEPARATOR}%{${save}${cub4}%}%K{cyan}%F{white} 🐳%{%k%f${restore}%}  "

    _sp_prompt_local="${base}${end_local}"
    _sp_prompt_docker="${base}${end_docker}"
    PROMPT="$_sp_prompt_local"
}

typeset -gA _sp_cmds

_sp_check() {
    [[ ${#_sp_cmds} -eq 0 ]] && return

    local d=0 t expect_cmd=1

    for t in ${(z)BUFFER}; do
        [[ "$t" == ('&&'|'||'|';'|'|'|'('|'if'|'then'|'else'|'do'|'while') ]] && { expect_cmd=1; continue; }
        [[ "$t" == *=* ]] && continue
        if (( expect_cmd )); then
            (( ${+_sp_cmds[$t]} )) && { d=1; break; }
            expect_cmd=0
        fi
    done

    (( d == _sp_docker )) && return
    _sp_docker=$d
    PROMPT=${${d:#0}:+$_sp_prompt_docker}
    PROMPT=${PROMPT:-$_sp_prompt_local}
    zle reset-prompt
}

# Use zle-line-pre-redraw instead of wrapping widgets (avoids conflicts)
_sp_line_check() {
    _sp_check
}

_sp_init() {
    # Add our check to existing zle-line-pre-redraw if any
    if [[ -n "$(functions zle-line-pre-redraw)" ]]; then
        # Chain with existing
        functions[_sp_orig_preraw]="$(functions zle-line-pre-redraw)"
        zle-line-pre-redraw() { _sp_orig_preraw; _sp_line_check; }
    else
        zle-line-pre-redraw() { _sp_line_check; }
    fi
    zle -N zle-line-pre-redraw

    add-zsh-hook -d precmd _sp_init
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _sp_precmd
add-zsh-hook precmd _sp_init
