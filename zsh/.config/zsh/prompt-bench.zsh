# Prompt latency probe. Source it IN THE SHELL THAT FEELS SLOW:
#
#   source ~/.config/zsh/prompt-bench.zsh
#
# then press Enter a few times and run a couple of commands. Every prompt
# prints a breakdown: total Enter-to-prompt time, how much of it was starship,
# and how much everything else (plugin hooks, zle). `prompt-bench-off` stops it.
#
# Not sourced automatically anywhere — this is a debugging tool.

zmodload zsh/datetime

typeset -g __pb_t0= __pb_starship=

__pb_preexec() { __pb_t0=$EPOCHREALTIME }

# Wrap starship's precmd so its share is measured separately.
if (( $+functions[prompt_starship_precmd] )) && ! (( $+functions[__pb_orig_starship] )); then
  functions -c prompt_starship_precmd __pb_orig_starship
  prompt_starship_precmd() {
    local t0=$EPOCHREALTIME
    __pb_orig_starship "$@"
    __pb_starship=$(( (EPOCHREALTIME - t0) * 1000 ))
  }
fi

__pb_precmd() {
  [[ -n $__pb_t0 ]] || return 0
  local total=$(( (EPOCHREALTIME - __pb_t0) * 1000 ))
  printf '\r[prompt-bench] total %.0f ms  |  starship %.0f ms  |  reszta %.0f ms\n' \
    "$total" "${__pb_starship:-0}" "$(( total - ${__pb_starship:-0} ))"
  __pb_t0= __pb_starship=
}

preexec_functions+=(__pb_preexec)
precmd_functions+=(__pb_precmd)   # appended last, so it runs after starship

prompt-bench-off() {
  preexec_functions=(${preexec_functions:#__pb_preexec})
  precmd_functions=(${precmd_functions:#__pb_precmd})
  if (( $+functions[__pb_orig_starship] )); then
    functions -c __pb_orig_starship prompt_starship_precmd
    unfunction __pb_orig_starship
  fi
  print '[prompt-bench] off'
}
