#!/bin/bash
set -x
{
  grep "=" ".env.template" | sed -e '/^#/d;/^\s*$/d;/=$/d'
  echo "TARGET_VERSION=${TARGET_VERSION}"
  echo "TARGET_BUILD=${TARGET_BUILD}"
  echo "TARGET_REGISTRY_TOKEN=${TARGET_REGISTRY_TOKEN}"
  echo "TARGET_REGISTRY_USER=${TARGET_REGISTRY_USER}"
}  >> "${GITHUB_ENV}"
#
echo "INFO: begin GITHUB_ENV="${GITHUB_ENV}""
cat "${GITHUB_ENV}"
echo "INFO: end GITHUB_ENV="${GITHUB_ENV}""

ln -s "${GITHUB_ENV}" .env
