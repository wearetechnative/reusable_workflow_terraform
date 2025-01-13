#!/bin/bash

# Find all .tf files and check for "git@" in module sources
echo "Checking for Terraform modules using 'git@' instead of 'github.com'..."
git_modules=$(grep -Hrin "source.*git@" . --include="*.tf")

if [ -n "$git_modules" ]; then
  echo "Found the following module sources using 'git@':"
  echo "$git_modules"
  echo "Please update the module sources to use 'github.com'."
  exit 1
else
  echo "No module sources using 'git@' found."
fi

