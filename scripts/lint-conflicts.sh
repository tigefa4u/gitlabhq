#!/bin/sh

output=$(git grep -E '^<<<<<<< HEAD' -- '*.haml' '*.js' '*.rb')
echo "$output"
test -z "$output"
