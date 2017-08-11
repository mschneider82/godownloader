#!/bin/sh
set -e
#  Code generated by godownloader. DO NOT EDIT.
#

usage() {
  this=$1
  cat <<EOF

$this: download binaries for mvdan/sh

Usage: $this [-b bindir] [version]
  -b set BINDIR or install directory.  Defaults to ./bin
  [version] is a version number from
  https://github.com/mvdan/sh/releases
  if absent, defaults to latest.  Consider setting GITHUB_TOKEN to avoid
  triggering GitHub rate limits.  See the following for more details:
  https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/

Generated by godownloader
 https://github.com/goreleaser/godownloader

EOF
  exit 2
}
parse_args() {
  #BINDIR is ./bin unless set be ENV
  # over-ridden by flag below

  BINDIR=${BINDIR:-./bin}
  while getopts "b:h?" arg; do
    case "$arg" in
      b) BINDIR="$OPTARG" ;;
      h) usage "$0" ;;
      \?) usage "$0" ;;
    esac
  done
  shift $((OPTIND - 1))
  VERSION=$1
}
adjust_version() {
  if [ -z "${VERSION}" ]; then
    echo "$PREFIX: checking GitHub for latest version"
    VERSION=$(github_last_release "$OWNER/$REPO")
  fi
  # if version starts with 'v', remove it
  VERSION=${VERSION#v}
}
adjust_binary() {
  if [ "$OS" = "windows" ]; then
    NAME="${NAME}.exe"
    BINARY="${BINARY}.exe"
  fi
}
# wrap all destructive operations into a function
# to prevent curl|bash network truncation and disaster
execute() {
  TMPDIR=$(mktmpdir)
  echo "$PREFIX: downloading from ${TARBALL_URL}"
  http_download "${TMPDIR}/${NAME}" "$TARBALL_URL"
  install -d "${BINDIR}"
  install "${TMPDIR}/${NAME}" "${BINDIR}/${BINARY}"
  echo "$PREFIX: installed ${BINDIR}/${BINARY}"
}

cat /dev/null <<EOF
------------------------------------------------------------------------
https://github.com/client9/shlib - portable posix shell functions
Public domain - http://unlicense.org
https://github.com/client9/shlib/blob/master/LICENSE.md
but credit (and pull requests) appreciated.
------------------------------------------------------------------------
EOF
is_command() {
  command -v "$1" >/dev/null
}
uname_os() {
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  echo "$os"
}
uname_arch() {
  arch=$(uname -m)
  case $arch in
    x86_64) arch="amd64" ;;
    x86) arch="386" ;;
    i686) arch="386" ;;
    i386) arch="386" ;;
    aarch64) arch="arm64" ;;
    armv5*) arch="arm5" ;;
    armv6*) arch="arm6" ;;
    armv7*) arch="arm7" ;;
  esac
  echo ${arch}
}
uname_os_check() {
  os=$(uname_os)
  case "$os" in
    darwin) return 0 ;;
    dragonfly) return 0 ;;
    freebsd) return 0 ;;
    linux) return 0 ;;
    android) return 0 ;;
    nacl) return 0 ;;
    netbsd) return 0 ;;
    openbsd) return 0 ;;
    plan9) return 0 ;;
    solaris) return 0 ;;
    windows) return 0 ;;
  esac
  echo "$0: uname_os_check: internal error '$(uname -s)' got converted to '$os' which is not a GOOS value. Please file bug at https://github.com/client9/shlib"
  return 1
}
uname_arch_check() {
  arch=$(uname_arch)
  case "$arch" in
    386) return 0 ;;
    amd64) return 0 ;;
    arm64) return 0 ;;
    armv5) return 0 ;;
    armv6) return 0 ;;
    armv7) return 0 ;;
    ppc64) return 0 ;;
    ppc64le) return 0 ;;
    mips) return 0 ;;
    mipsle) return 0 ;;
    mips64) return 0 ;;
    mips64le) return 0 ;;
    s390x) return 0 ;;
    amd64p32) return 0 ;;
  esac
  echo "$0: uname_arch_check: internal error '$(uname -m)' got converted to '$arch' which is not a GOARCH value.  Please file bug report at https://github.com/client9/shlib"
  return 1
}
untar() {
  tarball=$1
  case "${tarball}" in
    *.tar.gz | *.tgz) tar -xzf "${tarball}" ;;
    *.tar) tar -xf "${tarball}" ;;
    *.zip) unzip "${tarball}" ;;
    *)
      echo "Unknown archive format for ${tarball}"
      return 1
      ;;
  esac
}
mktmpdir() {
  test -z "$TMPDIR" && TMPDIR="$(mktemp -d)"
  mkdir -p "${TMPDIR}"
  echo "${TMPDIR}"
}
http_download() {
  local_file=$1
  source_url=$2
  header=$3
  headerflag=''
  destflag=''
  if is_command curl; then
    cmd='curl --fail -sSL'
    destflag='-o'
    headerflag='-H'
  elif is_command wget; then
    cmd='wget -q'
    destflag='-O'
    headerflag='--header'
  else
    echo "http_download: unable to find wget or curl"
    return 1
  fi
  if [ -z "$header" ]; then
    $cmd $destflag "$local_file" "$source_url"
  else
    $cmd $headerflag "$header" $destflag "$local_file" "$source_url"
  fi
}
github_api() {
  local_file=$1
  source_url=$2
  header=""
  case "$source_url" in
    https://api.github.com*)
      test -z "$GITHUB_TOKEN" || header="Authorization: token $GITHUB_TOKEN"
      ;;
  esac
  http_download "$local_file" "$source_url" "$header"
}
github_last_release() {
  owner_repo=$1
  giturl="https://api.github.com/repos/${owner_repo}/releases/latest"
  html=$(github_api - "$giturl")
  version=$(echo "$html" | grep -m 1 "\"tag_name\":" | cut -f4 -d'"')
  test -z "$version" && return 1
  echo "$version"
}
hash_sha256() {
  TARGET=${1:-/dev/stdin}
  if is_command gsha256sum; then
    hash=$(gsha256sum "$TARGET") || return 1
    echo "$hash" | cut -d ' ' -f 1
  elif is_command sha256sum; then
    hash=$(sha256sum "$TARGET") || return 1
    echo "$hash" | cut -d ' ' -f 1
  elif is_command shasum; then
    hash=$(shasum -a 256 "$TARGET" 2>/dev/null) || return 1
    echo "$hash" | cut -d ' ' -f 1
  elif is_command openssl; then
    hash=$(openssl -dst openssl dgst -sha256 "$TARGET") || return 1
    echo "$hash" | cut -d ' ' -f a
  else
    echo "hash_sha256: unable to find command to compute sha-256 hash"
    return 1
  fi
}
hash_sha256_verify() {
  TARGET=$1
  checksums=$2
  if [ -z "$checksums" ]; then
    echo "hash_sha256_verify: checksum file not specified in arg2"
    return 1
  fi
  BASENAME=${TARGET##*/}
  want=$(grep "${BASENAME}" "${checksums}" 2>/dev/null | tr '\t' ' ' | cut -d ' ' -f 1)
  if [ -z "$want" ]; then
    echo "hash_sha256_verify: unable to find checksum for '${TARGET}' in '${checksums}'"
    return 1
  fi
  got=$(hash_sha256 "$TARGET")
  if [ "$want" != "$got" ]; then
    echo "hash_sha256_verify: checksum for '$TARGET' did not verify ${want} vs $got"
    return 1
  fi
}
cat /dev/null <<EOF
------------------------------------------------------------------------
End of functions from https://github.com/client9/shlib
------------------------------------------------------------------------
EOF

OWNER=mvdan
REPO=sh
BINARY=shfmt
BINDIR=${BINDIR:-./bin}
PREFIX="$OWNER/$REPO"
OS=$(uname_os)
ARCH=$(uname_arch)

# make sure we are on a platform that makes sense
uname_os_check "$OS"
uname_arch_check "$ARCH"

# parse_args, show usage and exit if necessary
parse_args "$@"

# get or adjust version
adjust_version

NAME=${BINARY}_v${VERSION}_${OS}_${ARCH}

# adjust binary name based on OS
adjust_binary

# compute URL to download
TARBALL_URL=https://github.com/${OWNER}/${REPO}/releases/download/v${VERSION}/${NAME}

# do it
execute
