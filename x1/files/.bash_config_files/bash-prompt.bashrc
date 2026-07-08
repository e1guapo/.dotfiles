# -*- mode: sh; -*-
# Adapted from https://jdhao.github.io/2021/03/31/bash_prompt_config/

GRAY="\[\e[0;33m\]"
BOLD="\[\033[1m\]"
LT_CYAN="\[\e[1;36m\]"
LT_GREEN="\[\e[1;32m\]"
LT_RED="\[\e[1;31m\]"
GREEN="\[\e[0;32m\]"
PURPLE="\[\e[1;35m\]"
COLOR_NONE="\[\e[0m\]"

# Detect whether the current directory is a git repository.
function is_git_repository() {
  git branch > /dev/null 2>&1
}

function set_git_branch () {
    # Note that for new repo without commit, git rev-parse --abbrev-ref HEAD
    # will error out.
    if git rev-parse --abbrev-ref HEAD > /dev/null 2>&1; then
        BRANCH=" $(git rev-parse --abbrev-ref HEAD)"
    else
        BRANCH="<bare repo>"
    fi
}

function set_bash_prompt () {
    local exit_code=$?
    printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"
    PS1="\n"

    # Add virtual environment if active
    if [ -n "$VIRTUAL_ENV" ]; then
        PS1+="${GRAY}($(basename "$VIRTUAL_ENV"))${COLOR_NONE} "
    fi

    # Host and directory
    PS1+="${LT_CYAN}\u@\h${COLOR_NONE} ${LT_RED}${BOLD}✦${COLOR_NONE} "
    PS1+="${GREEN}\w${COLOR_NONE} • "

    # Add git branch
    if is_git_repository; then
        set_git_branch
        PS1+="${PURPLE}${BRANCH}${COLOR_NONE} • "
    fi

    # Current time in 12 hour format
    PS1+="${GREEN}$(date +'%r')${COLOR_NONE}\n"

    # Prompt character with color based on exit code
    if [ "$exit_code" == "0" ]; then
        PS1+="${LT_GREEN}"
    else
        PS1+="${LT_RED}"
    fi
    PS1+="λ${COLOR_NONE} "
}

if [[ -z "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="set_bash_prompt"
elif [[ "${PROMPT_COMMAND}" != *"set_bash_prompt"* ]]; then
    PROMPT_COMMAND="set_bash_prompt;${PROMPT_COMMAND}"
fi
