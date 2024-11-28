#!/usr/bin/env zsh

flox:env:xdg() {
  echo "loading XDG environment"
  local cwd=$(realpath "$PWD/.local")

  export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-${cwd}/.config}
  export XDG_CACHE_HOME=${XDG_CACHE_HOME:-${cwd}/.cache}
  export XDG_DATA_HOME=${XDG_DATA_HOME:-${cwd}/.local/share}
  export XDG_STATE_HOME=${XDG_STATE_HOME:-${cwd}/.local/state}
  export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-${cwd}/.local/xdg}

  mkdir -p \
        "${XDG_CONFIG_HOME}" \
        "${XDG_CACHE_HOME}" \
        "${XDG_DATA_HOME}" \
        "${XDG_STATE_HOME}" \
        "${XDG_RUNTIME_DIR}"
}

flox:env:gh() {
  local login=$( env GH_TOKEN=${GH_TOKEN:-$( pass show coding/github@work | head -n1 )} gh api user --jq '.login' )

  [[ -z "$login" ]] &&
    ( echo "gh not logged, cannot retrieve login name" 1>&2; return 1 )
}

flox:env:github() {
  [[ -d .github ]] ||
    return

  flox:env:gh

  echo 'loading github'

  local remote="$(git remote get-url origin)"
  local owner="$(echo $remote | cut -d'/' -f4)"
  local name="$(echo $remote | cut -d'/' -f5 | cut -d'.' -f1)"

  set -a
  GITHUB_OWNER=${owner}
  GITHUB_REPOSITORY=${owner}/${name}
  set +a
}


flox:env:maven:version() {
 set -a

 MAVEN_VERSION="$( env MAVEN_VERSION=3.9.9 \
   ${FLOX_ENV_PROJECT}/mvnw -N -q -Dexpression=maven.version -Doutput=/dev/stdout help:evaluate |
      grep -v -e '^\[.*\]' )"

 set +a
}

flox:env:maven() {
  [[ ! -x ./mvnw ]] && return

  flox:env:github

  echo "loading maven settings"

  local dotm2="${FLOX_ENV_PROJECT}/.m2"
  local repository="${FLOX_ENV_PROJECT}/.mvnrepository"

  set -a

  if [[ -d "${dotm2}" || -L "${dotm2}" ]]; then
    MAVEN_USER_CONFIG="${dotm2}"
    MAVEN_SETTINGS="${MAVEN_USER_CONFIG}/settings.xml"
    MAVEN_ARGS="${MAVEN_ARGS} --settings=${MAVEN_SETTINGS}"
  fi
  
  if [[ -d "${repository}" || -L "${repository}" ]]; then
    MAVEN_LOCAL_REPOSITORY="${repository}"
  fi

  set +a

  flox:env:maven:version
}

flox:env:debug() {
  case ${FLOX_DEBUG:-${1:-false}} in
    'true') set -x;;
    'false') set +x;;
  esac
}
