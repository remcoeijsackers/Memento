#!/usr/bin/env bats
# Tests for bin/mto. Run with: bats tests/
# MTO_BASH selects the bash that runs mto (CI uses /bin/bash 3.2 on macOS).

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export MEMENTO_HOME="$HOME/.local/share/memento"
  export NO_COLOR=1 MEMENTO_NO_FZF=1 SHELL=/bin/bash
  unset MEMENTO_INTEGRATION MEMENTO_ACTION_FILE MEMENTO_NO_HISTORY
  mkdir -p "$HOME" "$BATS_TEST_TMPDIR/p/website/src" "$BATS_TEST_TMPDIR/p/api/handlers" "$BATS_TEST_TMPDIR/sp ace/dir"
  P="$BATS_TEST_TMPDIR/p"
  MTO="$BATS_TEST_DIRNAME/../bin/mto"
  MTO_BASH="${MTO_BASH:-bash}"
}

mto() { "$MTO_BASH" "$MTO" "$@"; }

# ------------------------------------------------------------------- basics

@test "version and help" {
  run mto --version
  [ "$status" -eq 0 ]
  [[ "$output" == "memento 2."* ]]
  run mto help
  [[ "$output" == *"Directories"* ]]
  run mto help z
  [[ "$output" == *"mto z <part>"* ]]
}

@test "without a terminal, plain mto shows the overview" {
  run mto
  [ "$status" -eq 0 ]
  [[ "$output" == *"Tags (0)"* ]]
}

@test "unknown command fails" {
  run mto frobnicate
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown command"* ]]
}

# --------------------------------------------------------------------- tags

@test "tag without a name numbers t1, t2" {
  cd "$P/website"
  run mto tag
  [ "$status" -eq 0 ]
  cd "$P/api"
  mto tag
  run mto tags --plain
  [ "${lines[0]}" = "t1	$P/website" ]
  [ "${lines[1]}" = "t2	$P/api" ]
}

@test "tag with a name and a path, including spaces" {
  mto tag web "$P/website"
  mto tag spacey "$BATS_TEST_TMPDIR/sp ace/dir"
  run mto go spacey
  [ "$output" = "$BATS_TEST_TMPDIR/sp ace/dir" ]
}

@test "re-tagging a name moves it" {
  mto tag web "$P/website"
  run mto tag web "$P/api"
  [[ "$output" == *"moved tag web"* ]]
  run mto go web
  [ "$output" = "$P/api" ]
}

@test "tag refuses builtins, missing dirs and alias names" {
  run mto tag cd "$P/api"
  [ "$status" -eq 1 ]
  [[ "$output" == *"shell builtin"* ]]
  run mto tag x "$P/nope"
  [[ "$output" == *"not a directory"* ]]
  run mto tag "bad name!" "$P/api"
  [[ "$output" == *"invalid name"* ]]
  mto alias ll 'ls -la'
  run mto tag ll "$P/api"
  [[ "$output" == *"already an alias"* ]]
}

@test "hiding a command needs --force" {
  run mto tag ls "$P/api"
  [ "$status" -eq 1 ]
  [[ "$output" == *"--force"* ]]
  run mto tag ls "$P/api" --force
  [ "$status" -eq 0 ]
}

@test "go matches exact, prefix and part of the name" {
  mto tag website "$P/website"
  mto tag api "$P/api"
  [ "$(mto go website)" = "$P/website" ]
  [ "$(mto go web)" = "$P/website" ]
  [ "$(mto go eb 2>/dev/null)" = "$P/website" ]
  [ "$(mto go API)" = "$P/api" ]
}

@test "go with several matches and no terminal fails with code 2" {
  mto tag api1 "$P/api"
  mto tag api2 "$P/website"
  run mto go api
  [ "$status" -eq 2 ]
  [[ "$output" == *"matches several tags"* ]]
}

@test "go reports a tag whose directory disappeared" {
  mkdir "$BATS_TEST_TMPDIR/gone"
  mto tag gone "$BATS_TEST_TMPDIR/gone"
  rmdir "$BATS_TEST_TMPDIR/gone"
  run mto go gone
  [ "$status" -eq 1 ]
  [[ "$output" == *"no longer exists"* ]]
  run mto tags
  [[ "$output" == *"(missing)"* ]]
  run mto untag --missing
  [[ "$output" == *"removed gone"* ]]
  [ -z "$(mto tags --plain)" ]
}

@test "go writes a cd command to the action file" {
  mto tag web "$P/website"
  export MEMENTO_ACTION_FILE="$BATS_TEST_TMPDIR/action"
  : >"$MEMENTO_ACTION_FILE"
  mto go web
  [ "$(cat "$MEMENTO_ACTION_FILE")" = "cd -- $(printf '%q' "$P/website")" ]
}

@test "mto <tag> is a shortcut for mto go <tag>" {
  mto tag web "$P/website"
  [ "$(mto web)" = "$P/website" ]
}

@test "untag one, several and all" {
  mto tag a "$P/api"
  mto tag b "$P/api"
  mto tag c "$P/api"
  mto untag a b
  [ "$(mto tags --plain | cut -f1)" = "c" ]
  run mto untag --all
  [ "$status" -eq 1 ]
  [[ "$output" == *"-y"* ]]
  mto untag --all -y
  [ -z "$(mto tags --plain)" ]
}

# ------------------------------------------------------------------ history

@test "z jumps to the best matching visited directory" {
  mto _visit "$P/api/handlers"
  mto _visit "$P/website/src"
  mto _visit "$P/website/src"
  [ "$(mto z hand)" = "$P/api/handlers" ]
  [ "$(mto z src)" = "$P/website/src" ]
  [ "$(mto z api hand)" = "$P/api/handlers" ]
  run mto z nothing-like-this
  [ "$status" -eq 1 ]
}

@test "z prefers frequently visited directories" {
  mkdir -p "$P/a/proj" "$P/b/proj"
  mto _visit "$P/a/proj"
  for i in 1 2 3; do mto _visit "$P/b/proj"; done
  [ "$(mto z proj)" = "$P/b/proj" ]
}

@test "go falls back to history when no tag matches" {
  mto _visit "$P/api/handlers"
  run mto go handlers
  [ "$status" -eq 0 ]
  [[ "$output" == *"$P/api/handlers"* ]]
}

@test "history skips home, honours MEMENTO_NO_HISTORY and stays within its limit" {
  mto _visit "$HOME"
  MEMENTO_NO_HISTORY=1 mto _visit "$P/api"
  [ ! -s "$MEMENTO_HOME/history" ]
  for i in 1 2 3 4 5; do mkdir -p "$P/d$i"; MEMENTO_HISTORY_LIMIT=3 mto _visit "$P/d$i"; done
  [ "$(wc -l <"$MEMENTO_HOME/history" | tr -d ' ')" -eq 3 ]
  run mto recent
  [[ "$output" == *"d5"* ]]
}

# ------------------------------------------------------------------ aliases

@test "aliases: add, show, list, remove" {
  mto alias ll 'ls -la'
  mto alias greet echo "hello world"
  [ "$(mto alias ll)" = "ls -la" ]
  [ "$(mto alias greet)" = "echo hello world" ]
  run mto alias
  [[ "$output" == *"greet"* ]]
  mto unalias ll
  run mto alias ll
  [ "$status" -eq 1 ]
  mto unalias --all -y
  [ -z "$(mto _names aliases)" ]
}

@test "aliases keep quotes, dollars and backslashes" {
  mto alias tricky "echo 'it'\''s' \"\$HOME\" \\n"
  [ "$(mto alias tricky)" = "echo 'it'\\''s' \"\$HOME\" \\n" ]
}

@test "_defs output defines working aliases in bash" {
  mto tag web "$P/website"
  mto alias say "echo 'it'\''s \$((1+1))'"
  run bash -c "shopt -s expand_aliases; eval \"\$('$MTO_BASH' '$MTO' _defs bash)\"
say
alias web"
  [ "${lines[0]}" = "it's \$((1+1))" ]
  [ "${lines[1]}" = "alias web='mto go web'" ]
}

@test "_defs unaliases names that were removed" {
  run mto _defs bash "old1 old2"
  [[ "$output" == *"unalias old1"* ]]
  [[ "$output" == *"unalias old2"* ]]
}

# ------------------------------------------------------------------ scripts

@test "scripts: add, list with description, run, path, remove" {
  printf '#!/usr/bin/env bash\n# prints its argument\necho "got $1"\n' >"$BATS_TEST_TMPDIR/echoer.sh"
  mto script add "$BATS_TEST_TMPDIR/echoer.sh"
  [ -f "$BATS_TEST_TMPDIR/echoer.sh" ]
  [ -x "$MEMENTO_HOME/scripts/echoer" ]
  run mto scripts
  [[ "$output" == *"echoer"*"prints its argument"* ]]
  [ "$(mto run echoer x)" = "got x" ]
  [ "$(mto script path echoer)" = "$MEMENTO_HOME/scripts/echoer" ]
  mto script rm echoer
  [ ! -e "$MEMENTO_HOME/scripts/echoer" ]
}

@test "script add --move, custom name, duplicate and missing shebang" {
  printf 'echo hi\n' >"$BATS_TEST_TMPDIR/hi.sh"
  run mto script add "$BATS_TEST_TMPDIR/hi.sh" hello --move
  [ "$status" -eq 0 ]
  [[ "$output" == *"no #! line"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/hi.sh" ]
  printf '#!/bin/sh\necho hi\n' >"$BATS_TEST_TMPDIR/hello.sh"
  run mto script add "$BATS_TEST_TMPDIR/hello.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"already exists"* ]]
}

@test "script new creates an executable template" {
  run mto script new tool
  [ "$status" -eq 0 ]
  [ -x "$MEMENTO_HOME/scripts/tool" ]
  [ "$(mto run tool)" = "hello from tool" ]
}

@test "run executes aliases too" {
  mto alias hi 'echo "hi $0"'
  run mto run hi
  [[ "$output" == *"hi"* ]]
}

# ------------------------------------------------------------------- rename

@test "rename works for tags, aliases and scripts" {
  mto tag web "$P/website"
  mto alias ll 'ls -la'
  printf '#!/bin/sh\necho s\n' >"$BATS_TEST_TMPDIR/s.sh"
  mto script add "$BATS_TEST_TMPDIR/s.sh"
  mto rename web site
  mto rename ll lsl
  mto rename s sss
  [ "$(mto go site)" = "$P/website" ]
  [ "$(mto alias lsl)" = "ls -la" ]
  [ "$(mto run sss)" = "s" ]
  run mto rename site lsl
  [[ "$output" == *"already a alias"* ]]
}

# ----------------------------------------------------------- export / import

@test "export and import round-trip" {
  mto tag web "$P/website"
  mto alias ll 'ls -la'
  mto export "$BATS_TEST_TMPDIR/backup.txt"
  rm -rf "$MEMENTO_HOME"
  mto import "$BATS_TEST_TMPDIR/backup.txt"
  [ "$(mto go web)" = "$P/website" ]
  [ "$(mto alias ll)" = "ls -la" ]
}

# --------------------------------------------------------- install/uninstall

@test "install adds one block and keeps a backup" {
  echo "export FOO=1" >"$HOME/.bashrc"
  run mto install bash
  [ "$status" -eq 0 ]
  mto install bash
  [ "$(grep -c '>>> memento >>>' "$HOME/.bashrc")" -eq 1 ]
  grep -q "init bash" "$HOME/.bashrc"
  grep -q "export FOO=1" "$HOME/.bashrc"
  ls "$HOME"/.bashrc.memento-backup-* >/dev/null
}

@test "install picks the rc file for zsh" {
  run mto install zsh
  grep -q "init zsh" "$HOME/.zshrc"
}

@test "uninstall removes the block and --purge deletes data" {
  printf 'before\n' >"$HOME/.bashrc"
  mto install bash
  printf 'after\n' >>"$HOME/.bashrc"
  mto tag web "$P/website"
  mto uninstall
  ! grep -q memento "$HOME/.bashrc"
  grep -q before "$HOME/.bashrc"
  grep -q after "$HOME/.bashrc"
  [ -d "$MEMENTO_HOME" ]
  mto uninstall --purge -y
  [ ! -d "$MEMENTO_HOME" ]
}

@test "init refuses unsupported shells" {
  run mto init fish
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsupported shell"* ]]
}

# ------------------------------------------------------------------ migrate

legacy_rc() {
  mkdir -p "$BATS_TEST_TMPDIR/oldbin"
  printf '#!/bin/sh\necho legacy script\n' >"$BATS_TEST_TMPDIR/oldbin/_mto_hello.sh"
  cat >"$HOME/.zshrc" <<EOF
export KEEP=me
alias mto='/usr/local/bin/_mto_memento.sh' #alias made by Memento
alias t0='cd $P/website' #tag made by Memento
alias project='cd $P/api' #tag made by Memento
alias ll='ls -la' #alias made by Memento
alias hello='_mto_hello.sh' #script made by Memento
alias tagger='echo my own alias'
EOF
}

@test "migrate --dry-run changes nothing" {
  legacy_rc
  run mto migrate --dry-run --script-dir "$BATS_TEST_TMPDIR/oldbin"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tag    project"* ]]
  [[ "$output" == *"dry run"* ]]
  grep -q "tag made by Memento" "$HOME/.zshrc"
  [ -z "$(mto tags --plain)" ]
}

@test "migrate imports Memento 1 entries and cleans the rc file" {
  legacy_rc
  run mto migrate --script-dir "$BATS_TEST_TMPDIR/oldbin"
  [ "$status" -eq 0 ]
  [[ "$output" == *"imported 2 tags, 1 aliases and 1 scripts"* ]]
  [ "$(mto go project)" = "$P/api" ]
  [ "$(mto go t0)" = "$P/website" ]
  [ "$(mto alias ll)" = "ls -la" ]
  [ "$(mto run hello)" = "legacy script" ]
  ! grep -q "made by Memento" "$HOME/.zshrc"
  grep -q "export KEEP=me" "$HOME/.zshrc"
  grep -q "alias tagger='echo my own alias'" "$HOME/.zshrc"
  ls "$HOME"/.zshrc.memento-backup-* >/dev/null
}

@test "install points out Memento 1 entries" {
  legacy_rc
  run mto install zsh
  [[ "$output" == *"mto migrate"* ]]
}

# ------------------------------------------------------------- legacy flags

@test "Memento 1 flags still work" {
  cd "$P/api"
  mto -t proj
  [ "$(mto go proj)" = "$P/api" ]
  mto -a hi 'echo hi'
  [ "$(mto alias hi)" = "echo hi" ]
  run mto -ls
  [[ "$output" == *"proj"* ]]
  mto -ra hi
  run mto alias hi
  [ "$status" -eq 1 ]
  run mto -e
  [[ "$output" == *"not needed"* ]]
}

# ------------------------------------------------------------------- doctor

@test "doctor reports problems" {
  mkdir "$BATS_TEST_TMPDIR/tmpdir"
  mto tag t "$BATS_TEST_TMPDIR/tmpdir"
  rmdir "$BATS_TEST_TMPDIR/tmpdir"
  run mto doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *"not installed"* ]]
  [[ "$output" == *"missing directory"* ]]
}

@test "doctor is happy with a loaded integration" {
  mto tag web "$P/website"
  MEMENTO_INTEGRATION=bash run mto doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *"everything looks good"* ]]
}
