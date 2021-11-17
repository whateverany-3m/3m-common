#!/bin/bash
set -x
{
  grep "=" ".env.template" | sed -e '/^#/d;/^\s*$/d;/=$/d'
  echo "TARGET_VERSION=${GITHUB_REF:10}"
  echo "TARGET_BUILD=${{ github.run_number }}"
  echo "TARGET_REGISTRY_TOKEN=${{ secrets.TARGET_REGISTRY_TOKEN }}"
  echo "TARGET_REGISTRY_USER=${{ github.actor }}"
}  >> "${GITHUB_ENV}"
#
echo "INFO: GITHUB_ENV:"
ln -s "${GITHUB_ENV}" .env

