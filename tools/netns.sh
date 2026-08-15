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

export COLOR_{RESET,RED,GREEN,YELLOW,BLUE,GRAY} TAG_{INFO,WARNING,OK,ERROR}

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

export -f fail info ok warning

cmd_help() {
  cat >&2 <<EOF
$0: Tool for prototyping with Linux network namespaces

$0 help - show this message
$0 list - list all active network namespaces
$0 create <name> - create a new network namespace
$0 delete <name> - delete a network namespace
$0 enter <name> - spawn a new shell in a network namespace
$0 run <command> [arguments]... - run a command in a network namespace
EOF
}

cmd_list() {
  info "Listing all active network namespaces:"
  ls -1 /run/netns
}

namespace_setup() {
  set +euo pipefail
  info "Namespace created, confgiuring"
  hostname "$1"
  ok "Hostname configured"
  mount_namespace_setup "$1"
}

mount_namespace_setup() {
  set +euo pipefail
  mkdir -p "/run/mountns_overlays/$1/"{upper,work}
  mount -t overlay overlay /etc -o lowerdir=/etc,upperdir="/run/mountns_overlays/$1/upper",workdir="/run/mountns_overlays/$1/work"
  ok "Redirected changes in /etc to /run/mountns_overlays/$1/upper in the namespace"
  mkdir -p "/run/dhcpcd"
  mount -t tmpfs tmpfs /run/dhcpcd
  ok "Mounted private tmpfs on /run/dhcpcd"
  mount --bind /run/systemd /run/systemd -o ro
  ok "Made /run/systemd read-only"
  if [[ -L "/etc/resolv.conf" ]]
  then
    cp /etc/resolv.conf /etc/resolv.conf.new && mv /etc/resolv.conf.new /etc/resolv.conf
    ok "Converted /etc/resolv.conf to a standard file in the namespace"
  fi
}
export -f mount_namespace_setup
export -f namespace_setup

cmd_create() {
  if [[ -z "$1" ]]
  then
    fail "Missing required parameter: new network namespace name"
  fi
  if [[ -e "/run/netns/$1" ]]
  then
    fail "Network namespace '$1' already exists!"
  fi
  touch "/run/"{net,uts,mount}ns"/$1"
  unshare --net="/run/netns/$1" --uts="/run/utsns/$1" --mount="/run/mountns/$1" --propagation slave bash -c 'namespace_setup "$1"' 'namespace_setup' "$1"
  ok "Namespace '$1' created! Enter with '$0 enter $1'"
}

ensure_ns_exists() {
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
  if [[ ! -e "/run/mountns/$1" ]]
  then
    warning "Mount namespace for network namespace '$1' does not exist, creating"
    touch "/run/mountns/$1"
    unshare --mount="/run/mountns/$1" --propagation slave bash -c 'mount_namespace_setup $1' 'mount_namespace_setup' "$1"
  fi
}

cmd_enter() {
  ensure_ns_exists "$1"
  info "Entering network namespace '$1'"
  nsenter --net="/run/netns/$1" --uts="/run/utsns/$1" --mount="/run/mountns/$1" ${SHELL:-bash}
  info "Exiting network namespace '$1'"
}

cmd_run() {
  NSNAME="$1"
  shift
  ensure_ns_exists "$NSNAME"
  info "Running '$@' in network namespace '$NSNAME'"
  nsenter --net="/run/netns/$NSNAME" --uts="/run/utsns/$NSNAME" --mount="/run/mountns/$NSNAME" "$@"
}

cmd_delete() {
  if [[ -z "$1" ]]
  then
    fail "Missing required parameter: new network namespace name"
  fi
  if [[ ! -e "/run/netns/$1" && ! -e "/run/utsns/$1" && ! -e "/run/mountns/$1" && ! -e "/run/mountns_overlays/$1" ]]
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
  if [[ -e "/run/mountns/$1" ]]
  then
    info "Removing mount namespace for network namespace '$1'"
    umount "/run/mountns/$1" || true
    rm "/run/mountns/$1" && ok "Mount namespace for network namespace '$1' removed!" || true
  fi
  if [[ -e "/run/mountns_overlays/$1" ]]
  then
    info "Removing config file overrides for network namespace '$1'"
    rm -rf "/run/mountns_overlays/$1" && ok "Config file overrides for network namespace '$1' removed!" || true
  fi
}

if [[ $EUID -ne "0" ]]
then
  fail "This command must be run as root!"
fi

if [[ "`stat -Lc %i /proc/self/ns/net`" -ne "`stat -Lc %i /proc/1/ns/net`" ]]
then
  fail "You cannot manage namespaces from another network namespace"
fi

mkdir -p /run/netns /run/utsns /run/mountns_overlays

if [[ ! -d "/run/mountns" ]]
then
  mkdir /run/mountns
  mount tmpfs /run/mountns -t tmpfs -o private
fi

CMD="$1"
shift
case $CMD in
  "" | help)
    cmd_help
  ;;
  list | ls)
    cmd_list
  ;;
  create | new)
    cmd_create $1
  ;;
  delete | remove | rm)
    cmd_delete $1
  ;;
  enter)
    cmd_enter $1
  ;;
  run)
    cmd_run "$@"
  ;;
  *)
    fail "Unknown subcommand; run '$0 help' for help"
  ;;
esac
