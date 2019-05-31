#!/usr/bin/env bash

git remote -v

NEW_KARMA_SPECS_COUNT=`git diff --name-only origin/master --diff-filter A | grep spec/javascripts | wc -l | tr -d '[:space:]'`

echo "=> Found $NEW_KARMA_SPECS_COUNT new karma spec(s)."

if [ $NEW_KARMA_SPECS_COUNT -gt 0 ]; then
  echo "✖ ERROR: Please use Jest (spec/frontend) for new specs instead of Karma-Jasmine (spec/javascripts)."
  exit 1
fi

echo "✔︎ No new Karma specs found. Thank you!"
exit 0
