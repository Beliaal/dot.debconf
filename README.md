# dot.debconf
Personal Debian configuration files, shell helpers, and `/etc/skel` defaults.

## Contents
- `etc/apt/sources.list.d/debian.sources` — Debian stable APT sources in the modern `.sources` format.
- `etc/skel/.bash_aliases` — command aliases and shell helper loading.
- `etc/skel/.bash_ext` — Bash behaviour settings such as history, globbing, bell style, and GCC colours.
- `etc/skel/.bash_functions` — prompt customisation, Git prompt, battery helper, package helper, and colour helper.

## APT sources
`etc/apt/sources.list.d/debian.sources` is based on Debian stable and should work across version upgrades.

It includes:

- `stable`
- `stable-updates`
- `proposed-updates`
- `stable-backports`
- `stable-security`

## Installation notes
Copy system files as root so ownership and permissions stay correct.

Example:

```bash
sudo cp -a etc/skel/. /etc/skel/
sudo cp -a etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/
```

For an existing user, copy the relevant files manually to the user’s home directory instead of relying on `/etc/skel`.

## Useful packages
```bash
sudo apt install command-not-found git mc bash-completion plocate
```

Optional:
```bash
sudo apt install gitk
```

## TODO
- Add an install/bootstrap script.
- Document which files are safe for existing users and which are intended for `/etc/skel`.
- Review portability outside Debian.
