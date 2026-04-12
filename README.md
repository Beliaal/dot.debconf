# dot.debconf
personal dotfiles for debian

* /etc/apt/sources.list.d/debian.sources is now completely unisex (debian stable) and should work over version upgrades.Also updated to the new format, and a single file.
  * stable
  * stable-updates
  * proposed-updates
  * stable-backports
  * stable-security
* make sure to copy as root user to not screw up file ownership.

# TODO:
* lots of stuff
* moar
* fix /etc/skel/*
  * not too happy with the setup. it works. room for improvement...

# Packages:
command-not-found git mc bash-completion plocate
