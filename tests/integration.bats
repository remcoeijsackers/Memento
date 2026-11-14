#!/usr/bin/env bats
# End-to-end tests of the shell integration ("mto init") in bash and zsh.

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export MEMENTO_HOME="$HOME/.mto"
  export NO_COLOR=1 MEMENTO_NO_FZF=1
  unset MEMENTO_INTEGRATION MEMENTO_ACTION_FILE
  P="$BATS_TEST_TMPDIR/p"
  mkdir -p "$HOME" "$P/website" "$P/api/handlers" "$BATS_TEST_TMPDIR/sp ace"
  MTO="$BATS_TEST_DIRNAME/../bin/mto"
}

# Run a script, line by line like a terminal would, in a shell that has
# loaded the integration. (With -c, zsh parses everything before running, so
# aliases defined on the way would not be seen yet.)
in_shell() { # shell script
  local shell="$1" file="$BATS_TEST_TMPDIR/script.$1"
  if [ "$shell" = zsh ]; then
    command -v zsh >/dev/null || skip "zsh not installed"
    printf 'eval "$(%q init zsh)"\n%s\n' "$MTO" "$2" >"$file"
    zsh -f "$file"
  else
    printf 'shopt -s expand_aliases\neval "$(%q init bash)"\n%s\n' "$MTO" "$2" >"$file"
    bash --norc --noprofile "$file"
  fi
}

scenario() {
  cat <<EOF
cd '$P/website'; mto tag web 2>/dev/null
cd '$BATS_TEST_TMPDIR/sp ace'; mto tag spacey 2>/dev/null
cd /
web
echo "1:\$PWD"
spacey
echo "2:\$PWD"
mto go we
echo "3:\$PWD"
mto alias hi 'echo "alias works"' 2>/dev/null
hi
'$MTO' tag api '$P/api' 2>/dev/null
_mto_sync
api
echo "4:\$PWD"
cd '$P/api/handlers'; _mto_visit; cd /
mto z hand
echo "5:\$PWD"
mto unalias hi 2>/dev/null
_mto_sync
hi 2>/dev/null || echo "6:gone"
EOF
}

check_scenario() {
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "1:$P/website" ]
  [ "${lines[1]}" = "2:$BATS_TEST_TMPDIR/sp ace" ]
  [ "${lines[2]}" = "3:$P/website" ]
  [ "${lines[3]}" = "alias works" ]
  [ "${lines[4]}" = "4:$P/api" ]
  [ "${lines[5]}" = "5:$P/api/handlers" ]
  [ "${lines[6]}" = "6:gone" ]
}

@test "bash: tags, aliases, sync from another terminal, z" {
  run in_shell bash "$(scenario)"
  check_scenario
}

@test "zsh: tags, aliases, sync from another terminal, z" {
  run in_shell zsh "$(scenario)"
  check_scenario
}

@test "scripts are on PATH in the shell" {
  printf '#!/bin/sh\necho "from script"\n' >"$BATS_TEST_TMPDIR/hello.sh"
  "$MTO" script add "$BATS_TEST_TMPDIR/hello.sh" 2>/dev/null
  run in_shell bash "hello"
  [ "$output" = "from script" ]
  run in_shell zsh "hello"
  [ "$output" = "from script" ]
}

@test "the wrapper keeps the exit status" {
  run in_shell bash "mto go nothing 2>/dev/null; echo \"status=\$?\""
  [ "$output" = "status=1" ]
}

@test "bash completion knows commands and tag names" {
  "$MTO" tag web "$P/website" 2>/dev/null
  run in_shell bash 'COMP_WORDS=(mto go ""); COMP_CWORD=2; _mto_complete; echo "${COMPREPLY[*]}"
COMP_WORDS=(mto ta); COMP_CWORD=1; _mto_complete; echo "${COMPREPLY[*]}"'
  [ "${lines[0]}" = "web" ]
  [ "${lines[1]}" = "tag tags" ]
}

@test "init can be loaded twice without duplicating the prompt hook" {
  run in_shell bash "eval \"\$('$MTO' init bash)\"; echo \"\$PROMPT_COMMAND\""
  [ "$output" = "_mto_prompt" ]
}
