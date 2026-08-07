#!/bin/bash
set +euo pipefail

# formatting
COLOR_RESET=`printf '\e[0m'`

# colors
COLOR_RED=`printf '\e[31m'`
COLOR_GREEN=`printf '\e[32m'`
COLOR_YELLOW=`printf '\e[33m'`
COLOR_BLUE=`printf '\e[34m'`
COLOR_GRAY=`printf '\e[90m'`

# tags
TAG_ERROR="${COLOR_GRAY}[${COLOR_RED}ERROR${COLOR_GRAY}]${COLOR_RESET}"
TAG_WARNING="${COLOR_GRAY}[${COLOR_YELLOW}WARNING${COLOR_GRAY}]${COLOR_RESET}"
TAG_OK="${COLOR_GRAY}[${COLOR_GREEN}OK${COLOR_GRAY}]${COLOR_RESET}"
TAG_INFO="${COLOR_GRAY}[${COLOR_BLUE}INFO${COLOR_GRAY}]${COLOR_RESET}"

fail() {
  echo "$TAG_ERROR $@" >&2;
  exit 1
}

info() {
  echo "$TAG_INFO $@" >&2;
}

ok() {
  echo "$TAG_OK $@" >&2;
}

warning() {
  echo "$TAG_WARNING $@" >&2;
}

cmd_help() {
  cat >&2 <<EOF
$0: Tool for prototyping with Linux network namespaces

$0 help - show this message
$0 list - list all active network namespaces
$0 create <name> - create a new network namespace
$0 delete <name> - delete a network namespace
$0 enter <name> - spawn a new shell in a network namespace
EOF
}

cmd_list() {
  info "Listing all active network namespaces:"
  ls -1 /run/netns
}

cmd_create() {
  if [[ -z "$1" ]]
  then
    fail "Missing required parameter: new network namespace name"
  fi
  if [[ -e "/run/netns/$1" ]]
  then
    fail "Network namespace '$1' already exists!"
  fi
  touch "/run/"{net,uts}ns"/$1"
  unshare --net="/run/netns/$1" --uts="/run/utsns/$1" hostname "$1"
  ok "Namespace '$1' created! Enter with '$0 enter $1'"
}

cmd_enter() {
  if [[ -z "$1" ]]
  then
    fail "Missing required parameter: new network namespace name"
  fi
  if [[ ! -e "/run/netns/$1" ]]
  then
    fail "Network namespace '$1' does not exist!"
  fi
  if [[ ! -e "/run/utsns/$1" ]]
  then
    warning "UTS namespace for network namespace '$1' does not exist, creating"
    touch "/run/utsns/$1"
    unshare --uts="/run/utsns/$1" hostname "$1"
  fi
  info "Entering network namespace '$1'"
  nsenter --net="/run/netns/$1" --uts="/run/utsns/$1" ${SHELL:-bash}
  info "Exiting network namespace '$1'"
}

cmd_delete() {
  if [[ -z "$1" ]]
  then
    fail "Missing required parameter: new network namespace name"
  fi
  if [[ ! -e "/run/netns/$1" && ! -e "/run/utsns/$1" ]]
  then
    fail "Network namespace '$1' does not exist!"
  fi
  if [[ -e "/run/netns/$1" ]]
  then
    info "Removing network namespace '$1'"
    umount "/run/netns/$1" || true
    rm "/run/netns/$1" && ok "Network namespace '$1' removed!" || true
  fi
  if [[ -e "/run/utsns/$1" ]]
  then
    info "Removing UTS namespace for network namespace '$1'"
    umount "/run/utsns/$1" || true
    rm "/run/utsns/$1" && ok "UTS namespace for network namespace '$1' removed!" || true
  fi
}

if [[ $EUID -ne "0" ]]
then
  fail "This command must be run as root!"
fi

mkdir -p /run/netns /run/utsns
case $1 in
  "" | help)
    cmd_help
  ;;
  list | ls)
    cmd_list
  ;;
  create | new)
    cmd_create $2
  ;;
  delete | remove | rm)
    cmd_delete $2
  ;;
  enter)
    cmd_enter $2
  ;;
  *)
    fail "Unknown subcommand; run '$0 help' for help"
  ;;
esac
