# Memento

**Stop remembering where things live.** Memento (`mto`) tags the directories you work in, keeps
your aliases and scripts in one place, and learns where you go, so getting around the terminal
takes a word instead of a path.

![Memento demo](docs/demo.svg)

```sh
mto tag website        # tag the current directory
website                # …and jump back to it from anywhere
mto go web             # part of the name is enough
mto z hand             # jump to ~/code/api/handlers: Memento remembers where you've been
mto alias gs 'git status --short'   # works immediately, in every open terminal
mto script add deploy.sh            # now "deploy" runs from anywhere
mto                    # interactive menu for all of the above
```

Works in **bash** (3.2 and newer, so also the macOS default) and **zsh**. It is one script with
no dependencies, and uses [fzf](https://github.com/junegunn/fzf) for fuzzy picking if you have it.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/remcoeijsackers/Memento/main/install.sh | bash
```

Or from a clone:

```sh
git clone https://github.com/remcoeijsackers/Memento && cd Memento && ./install.sh
```

This puts `mto` in `~/.local/bin` (override with `PREFIX=…`) and adds one line to your
`~/.zshrc` or `~/.bashrc` (a backup is made first). Open a new terminal and you're set.
`mto doctor` checks that everything works.

**Just want to look around first?** `./bin/mto demo` opens a throwaway shell with sample tags,
aliases and a script. Nothing is installed, and everything is deleted when you type `exit`.

## Tags: name a directory once, jump there forever

```sh
cd ~/code/clients/acme/website
mto tag acme            # or just "mto tag" for automatic names: t1, t2, …
acme                    # every tag is a command
mto go ac               # exact name, unique prefix or any part of the name or folder
mto go                  # pick from a list
mto tags                # list them (broken ones are marked "missing")
mto tag acme ~/elsewhere   # move a tag
mto rename acme acme-web
mto untag acme | mto untag --missing | mto untag --all
```

Memento refuses names that would break your shell (`cd`, `if`, …). Hiding a real command such as
`ls` requires `--force`.

## z: jump to directories you've visited

Memento quietly records the directories you work in. `mto z` takes parts of a path and jumps to
the best match, ranked by how often and how recently you were there:

```sh
mto z hand          # → ~/code/api/handlers
mto z api hand      # parts must appear in order
mto z               # pick from your most used directories
mto recent          # list them
```

`mto go` falls back to this when no tag matches. Set `MEMENTO_NO_HISTORY=1` to turn recording off.

## Aliases

```sh
mto alias gs 'git status --short'
mto alias                 # list
mto alias gs              # show one
mto unalias gs            # remove (or --all)
```

Aliases are stored by Memento rather than in your rc file. They work immediately and show up in
your other open terminals at their next prompt.

## Scripts

```sh
mto script add ~/Downloads/backup.sh       # copied in, made executable, on your PATH as "backup"
mto script add tool.sh mytool --move       # pick a name, move instead of copy
mto script new cleanup                     # start from a template in $EDITOR
mto script edit cleanup
mto scripts                                # list, with each script's first comment as description
mto run cleanup --dry-run                  # same as just typing: cleanup --dry-run
mto script rm cleanup
```

## Interactive menu

Run `mto` without arguments to jump to a tag or recent directory, run an alias or script, edit a
script, tag the current directory or add an alias. Type to filter, use the arrow keys (or ctrl-n
and ctrl-p), then press enter. Esc or ctrl-c cancels. With fzf installed you get fuzzy search.

## Everything else

| Command | What it does |
|---------|--------------|
| `mto ls` | everything at a glance |
| `mto doctor` | checks the installation, broken tags and name clashes |
| `mto export backup.txt` / `mto import backup.txt` | move tags and aliases to another machine |
| `mto install [bash\|zsh]` / `mto uninstall [--purge]` | add or remove the line in your rc file (`--purge` also deletes your data) |
| `mto help <command>` | details for each command |

Tab completion for commands, tag names, aliases and scripts is included for bash and zsh.

## Upgrading from Memento 1

Memento 1 wrote its tags, aliases and scripts directly into your rc file and needed a shell
restart after every change. To move everything over:

```sh
mto migrate --dry-run   # see what will be imported
mto migrate             # import, then remove the old lines from your rc file (after a backup)
```

Old scripts are copied from `/usr/local/bin` (use `--script-dir` if you picked another folder).
The old flags still work: `mto -t`, `-a`, `-s`, `-ls`, `-ia`, `-ra`, `-rta` and the rest.

## How it works

- Your data lives in `~/.local/share/memento` (`$MEMENTO_HOME`): `tags` and `aliases` are plain
  `name<TAB>value` files, `scripts/` holds your scripts, and `history` holds visited directories.
- Your rc file only gets `eval "$(mto init zsh)"`. That defines a small `mto` shell function
  (a separate program can't change your shell's directory, but a function can), defines an alias
  per tag and alias, puts `scripts/` on your PATH, and adds a prompt hook. The hook reloads changes
  made in other terminals and records directories for `mto z`.
- Nothing is ever written to your rc file except that one marked block.

## Development

```sh
bats tests/                    # unit and shell-integration tests (bash and zsh)
python3 tests/interactive.py   # drives the picker through a real terminal (needs pexpect)
shellcheck -s bash bin/mto
```

CI runs the tests on Linux and macOS, including macOS's own bash 3.2.

## License

[MIT](LICENSE)
