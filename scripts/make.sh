#!/bin/sh
if [ "${CI_DEBUG}" = "true"]; then
  set -x
fi

_ci_env() {
  echo "INFO: _ci_env"
  if [ "${GITHUB_ENV}" = "" ]; then
    GITHUB_ENV=$(mktemp)
  fi
  {
    grep "=" ".env.template" | sed -e '/^#/d;/^\s*$/d;/=$/d'
    echo "TARGET_VERSION=${TARGET_VERSION}"
    echo "TARGET_BUILD=${TARGET_BUILD}"
    echo "TARGET_REGISTRY_TOKEN=${TARGET_REGISTRY_TOKEN}"
    echo "TARGET_REGISTRY_USER=${TARGET_REGISTRY_USER}"
  }  >> "${GITHUB_ENV}"
  
  echo "INFO: begin GITHUB_ENV="${GITHUB_ENV}""
  cat "${GITHUB_ENV}"
  echo "INFO: end GITHUB_ENV="${GITHUB_ENV}""
  
  if [ \! -e "${ENVFILE}" ]; then
    cp "${GITHUB_ENV}" "${ENVFILE}"
  fi
}

_pre_login() {
  echo "INFO: _pre_login"
  echo "${TARGET_REGISTRY_TOKEN}" | docker login --username "${TARGET_REGISTRY_USER}" --password-stdin "${TARGET_REGISTRY}"
} 

_run_build() {
  echo "INFO: _run_build"
  docker build \
    ${DOCKER_ARGS} \
    --no-cache \
    --tag "${TARGET_REGISTRY}${TARGET_GROUP}${TARGET_IMAGE}:${TARGET_SEMANTIC_RC}" \
    --tag "${TARGET_REGISTRY}${TARGET_GROUP}${TARGET_IMAGE}:${TARGET_SEMANTIC_VERSION}" \
    --file Dockerfile \
    .
}

_run_lint() {
  echo "INFO: _run_lint"
}

_run_publish() {
  echo "INFO: _run_publish"
  docker push "${TARGET_REGISTRY}${TARGET_GROUP}${TARGET_IMAGE}:${TARGET_SEMANTIC_RC}"
  docker push "${TARGET_REGISTRY}${TARGET_GROUP}${TARGET_IMAGE}:${TARGET_SEMANTIC_VERSION}"
}

_post_logout() {
  echo "INFO: _post_logout"
  docker logout "${TARGET_REGISTRY}"
}

ci_env() {
  echo "INFO: ###############################################################"
  echo "INFO: ci_env"
  echo "INFO: ###############################################################"
  _ci_env
}

ci_pre_action() {
  echo "INFO: ###############################################################"
  echo "INFO: ci_pre_action"
  echo "INFO: ###############################################################"
  _pre_login
}

ci_run_action() {
  echo "INFO: ###############################################################"
  echo "INFO: ci_run_action"
  echo "INFO: ###############################################################"
  _run_build
  _run_lint
  _run_publish
} 

ci_post_action() {
  echo "INFO: ###############################################################"
  echo "INFO: ci_post_action"
  echo "INFO: ###############################################################"
  _post_logout
}  

_env_() {
  echo "INFO: _env_"
  if [ "${2}" = "" ]; then
      echo "Environment variable $* not set"
      echo "Please check README.md for variables required"
      exit 1
  fi
  echo "INFO: ${*}='${${*}}'"
}

_env() {
  echo "INFO: _env"
  echo "INFO: Checking for .env"
  if [ \! -e "${ENVFILE}" ]; then
    echo "INFO: .env doesn't exist, copying ${ENVFILE}"
    cp .env.template "${ENVFILE}"
  fi
}

for TARGET in ${@}
do
  echo "INFO: TARGET=${TARGET}"
  case "${TARGET}" in
    (ci_env)
      ci_env
      ;;
    (ci_pre_action)
      ci_pre_action
      ;;
    (ci_run_action)
      ci_run_action
      ;;
    (ci_post_action)
      ci_post_action
      ;;
    (_pre_login)
      _pre_login
      ;;
    (_run_build)
      _run_build
      ;;
    (_run_lint)
      _run_lint
      ;;
    (_run_publish)
      _run_publish
      ;;
    (_env_action)
      _env_action
      ;;
    (_post_logout)
      _post_logout
      ;;
    (_env)
      _env
      ;;
    (*)
      echo "Usage: option $0 is unknown"
      exit 2
      ;;
  esac
done

