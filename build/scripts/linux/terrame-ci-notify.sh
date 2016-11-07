#!/bin/bash

set +x # It forces to do not display anything among this script execution.
#
## It notifies GitHub Status platform using api v3
# usage: ./send.sh COMMIT_HASH STATUS_CONTEXT STATUS JOB_URL STATUS_DESCRIPTION

# Github initial status
GITHUB_STATUS="$3"
# GitHub current commit
GITHUB_COMMIT=$1
# GitHub description status
GITHUB_DESCRIPTION=$5
# Status Context: The display name
GITHUB_CONTEXT=$2
# Current Jenkins URL
JENKINS_URL=$4

REPO_NAME="$6"

# Defining default repository if there is not.
if [ "$REPO_NAME" == "" ]; then
  REPO_NAME="terrame"
fi

# TerraME Bot Token. REMEMBER to define "set +x before exporting this variable in shell. It is very important. Otherwise, the access token will show in console"
ACCESS_TOKEN="$TERRAME_TOKEN"
# Preparing JSON to GitHub
JSON="{\"state\": \"$GITHUB_STATUS\", \"target_url\": \"$JENKINS_URL\", \"description\": \"$GITHUB_DESCRIPTION\", \"context\": \"$GITHUB_CONTEXT\"}"

# A common function to notify GitHub
function request() {
  curl --silent -H "Content-Type: application/json" -X POST -d "$1" https://api.github.com/repos/terrame/$4/statuses/$2?access_token=$3 > /dev/null
}

request "$JSON" "$GITHUB_COMMIT" "$ACCESS_TOKEN" "$REPO_NAME"
exit $?