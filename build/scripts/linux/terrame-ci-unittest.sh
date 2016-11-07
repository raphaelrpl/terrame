#!/bin/bash -l
# 
## It enables to run terrame unittest on UNIX environments.
## **Remember to export some variables before**
# 
## TERRAME_PATH - Path to TerraME installation
## TERRAME_GIT_DIR - Path to TerraME git directory
#
## Usage
# ./terrame-ci-unittest.sh PACKAGE COMMIT
# 
# PACKAGE - Represents which package will be tested
# COMMIT - Pull Request Commit Hash used to notify GitHub

# GitHub Status Name
GITHUB_CONTEXT="Functional test of package $1"
# GitHub Commit hash
COMMIT=$2
# GitHub Status URL
TARGET_URL="$BUILD_URL/consoleFull"

# Exporting TerraME environment variables
export TME_PATH="$TERRAME_PATH/bin"
export PATH=$PATH:$TME_PATH
export LD_LIBRARY_PATH=$TME_PATH

# Sending initial status (pending) to GitHub
$TERRAME_GIT_DIR/build/scripts/linux/terrame-ci-notify.sh $COMMIT "$GITHUB_CONTEXT" "pending" "$TARGET_URL" "Running tests."

terrame -version

# Extra commands if package is terralib
TERRAME_COMMANDS=""
if [ "$1" == "terralib" ]; then
  TERRAME_COMMANDS="-package terralib"
fi

terrame -color $TERRAME_COMMANDS -test test.lua 2> /dev/null
# Retrieving TerraME exit code
RESULT=$?

if [ $RESULT -eq 0 ]; then
  GITHUB_STATUS="success"
  GITHUB_DESCRIPTION="Tests executed successfully"
elif [ $RESULT -eq 255 ]; then
  GITHUB_STATUS="failure"
  GITHUB_DESCRIPTION="$RESULT or more errors found"
else
  GITHUB_STATUS="failure"
  GITHUB_DESCRIPTION="$RESULT tests failed"
fi
# Removing log files
rm -rf .terrame*

$TERRAME_GIT_DIR/build/scripts/linux/terrame-ci-notify.sh $COMMIT "$GITHUB_CONTEXT" "$GITHUB_STATUS" "$TARGET_URL" "$GITHUB_DESCRIPTION"

exit $RESULT