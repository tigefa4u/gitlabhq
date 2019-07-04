#!/bin/bash

# TODO, replace with a new repository
readonly FOSS_REPOSITORY="https://gitlab.com/marin/gitlab-ce.git"

# TODO, replace with a correct bot user
function git_config_user() {
  git config --global user.email "marin+release-tools@gitlab.com"
  git config --global user.name "GitLab Release Tools Bot"
}

# Backstop 1: Use a global specific git ignore file
# In the global git ignore file specify that all directories (and files) in the
# root named "ee" cannot get commited
function git_config_exclude() {
  echo "ee/*" >> /tmp/ignore
  git config --global --add core.excludesFile '/tmp/ignore'
}

# Use HTTPS clone to avoid dealing with SSH keys
function git_credentials() {
  echo "https://$USERNAME:$TOKEN@gitlab.com" > ~/.git-credentials
  git config --global credential.helper store
}

# Clone only master of the FOSS repository since that is the only branch we are
# going to commit to
function git_clone_foss() {
  git clone --single-branch --branch "master" $FOSS_REPOSITORY /tmp/gitlab-foss
}

# Remove the ee directory from the current gitlab(-ee) repository
# Also remove .git directory to ensure that we don't commit EE history
function remove_ee_files() {
  rm -rf .git ee/
}

function copy_new_files() {
  cp -rf * /tmp/gitlab-foss/
}

function foss_commit() {
  cd /tmp/gitlab-foss
  git add --all
  git commit --allow-empty -m "Automatic sync `date +'%Y-%m-%d %H:%M:%S'`"
  git push origin master
}

if [[ -z "$CI" ]]; then
  echo "Not running in CI, nothing to do"
  exit 0
else
  git_config_user
  git_credentials
  git_config_exclude
  git_clone_foss
  remove_ee_files
  copy_new_files
  foss_commit
fi
